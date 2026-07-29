import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/player_repository.dart';
import '../../services/stats_service.dart';
import 'new_match_state.dart';

class NewMatchCubit extends Cubit<NewMatchState> {
  NewMatchCubit({
    required PlayerRepository playerRepository,
    required MatchRepository matchRepository,
  })  : _playerRepo = playerRepository,
        _matchRepo = matchRepository,
        super(NewMatchState(
          players: playerRepository.players,
          matches: matchRepository.matches,
        )) {
    _playersSub = _playerRepo.watchPlayers().listen(_onPlayersChanged);
    _matchesSub = _matchRepo.watchMatches().listen(_onMatchesChanged);
  }

  final PlayerRepository _playerRepo;
  final MatchRepository _matchRepo;
  late final StreamSubscription<List<Player>> _playersSub;
  late final StreamSubscription<List<GameMatch>> _matchesSub;
  List<Player>? _deferredPlayers;
  int _signal = 0;

  int _nextSignal() => ++_signal;

  void _onPlayersChanged(List<Player> players) {
    if (isClosed) return;
    if (state.isSaving || state.lastVictory != null) {
      _deferredPlayers = players;
      return;
    }
    _reconcilePlayers(players);
  }

  void _onMatchesChanged(List<GameMatch> matches) {
    if (isClosed) return;
    emit(state.copyWith(matches: List.unmodifiable(matches)));
  }

  void _reconcilePlayers(
    List<Player> players, {
    bool? isSaving,
    NewMatchFeedback? fallbackFeedback,
  }) {
    final presentIds = players
        .where((player) => player.isPresent)
        .map((player) => player.id)
        .toSet();
    final assignment = Map<String, int>.unmodifiable(
      Map.fromEntries(
        state.assignment.entries.where(
          (entry) =>
              presentIds.contains(entry.key) &&
              (entry.value == 1 || entry.value == 2),
        ),
      ),
    );
    final invalidated = assignment.length != state.assignment.length;
    final interruptedMatch = invalidated && state.kickedOff;
    final feedbackKind = interruptedMatch
        ? NewMatchFeedback.playersUnavailable
        : fallbackFeedback;

    emit(state.copyWith(
      players: players,
      assignment: assignment,
      isRivalry: invalidated ? false : state.isRivalry,
      kickedOff: interruptedMatch ? false : null,
      scorerIds: interruptedMatch ? const [] : null,
      score1: interruptedMatch ? 0 : null,
      score2: interruptedMatch ? 0 : null,
      isSaving: isSaving,
      lastFeedback: feedbackKind != null
          ? FeedbackEvent(
              kind: feedbackKind,
              signalId: _nextSignal(),
            )
          : state.lastFeedback,
    ));
  }

  void _feedback(NewMatchFeedback kind) {
    emit(state.copyWith(
      lastFeedback: FeedbackEvent(kind: kind, signalId: _nextSignal()),
    ));
  }

  void setTeam(String playerId, int team) {
    if (state.kickedOff || state.isSaving || (team != 1 && team != 2)) return;
    if (!state.present.any((player) => player.id == playerId)) return;

    final current = Map<String, int>.from(state.assignment);
    final isSame = current[playerId] == team;
    if (isSame) {
      current.remove(playerId);
    } else {
      final targetTeam = state.team(team);
      if (targetTeam.length >= state.mode.teamSize) return;
      current[playerId] = team;
    }
    emit(state.copyWith(
      assignment: Map.unmodifiable(current),
      isRivalry: false,
    ));
  }

  void setMatchMode(MatchMode mode) {
    if (state.kickedOff || state.isSaving || state.mode == mode) return;
    emit(state.copyWith(
      mode: mode,
      isRivalry: false,
      assignment: const {},
      scorerIds: const [],
      score1: 0,
      score2: 0,
      clearLastGoal: true,
      clearLastFeedback: true,
    ));
  }

  void setRivalry(bool enabled) {
    if (state.kickedOff || state.isSaving || !state.teamsValid) return;
    emit(state.copyWith(isRivalry: enabled));
  }

  void kickoff() {
    if (state.isSaving || state.kickedOff) return;
    if (!state.teamsValid) {
      _feedback(NewMatchFeedback.invalidTeams);
      return;
    }
    HapticFeedback.mediumImpact();
    emit(state.copyWith(kickedOff: true, score1: 0, score2: 0));
  }

  void addGoal(int team, String scorerId) {
    if (!state.kickedOff || state.isSaving || (team != 1 && team != 2)) return;
    final teamPlayers = state.team(team);
    if (!teamPlayers.contains(scorerId)) return;

    final scorerName = StatsService.playerName(state.players, scorerId);
    final scorerIds = List<String>.from(state.scorerIds)..add(scorerId);

    if (team == 1) {
      emit(state.copyWith(
        scorerIds: List.unmodifiable(scorerIds),
        score1: state.score1 + 1,
        lastGoal: GoalEvent(
          team: 1,
          scorerId: scorerId,
          scorerName: scorerName,
          signalId: _nextSignal(),
        ),
      ));
    } else if (team == 2) {
      emit(state.copyWith(
        scorerIds: List.unmodifiable(scorerIds),
        score2: state.score2 + 1,
        lastGoal: GoalEvent(
          team: 2,
          scorerId: scorerId,
          scorerName: scorerName,
          signalId: _nextSignal(),
        ),
      ));
    }
  }

  void removeGoal(int team) {
    if (!state.kickedOff || state.isSaving) return;
    final teamPlayers = state.team(team).toSet();
    if (teamPlayers.isEmpty) return;

    final scorerIds = List<String>.from(state.scorerIds);
    final removeIndex = scorerIds.lastIndexWhere(teamPlayers.contains);
    if (removeIndex == -1) return;

    scorerIds.removeAt(removeIndex);
    HapticFeedback.selectionClick();
    if (team == 1 && state.score1 > 0) {
      emit(state.copyWith(
        scorerIds: List.unmodifiable(scorerIds),
        score1: state.score1 - 1,
      ));
    } else if (team == 2 && state.score2 > 0) {
      emit(state.copyWith(
        scorerIds: List.unmodifiable(scorerIds),
        score2: state.score2 - 1,
      ));
    }
  }

  void resetScore() {
    if (!state.kickedOff || state.isSaving) return;
    emit(state.copyWith(score1: 0, score2: 0, scorerIds: const []));
  }

  void abortMatch() {
    if (state.isSaving) return;
    emit(state.copyWith(
      kickedOff: false,
      scorerIds: const [],
      score1: 0,
      score2: 0,
    ));
  }

  Future<void> save() async {
    if (state.isSaving || state.lastVictory != null) return;
    if (!state.kickedOff || !state.teamsValid) {
      _feedback(NewMatchFeedback.invalidTeams);
      return;
    }
    if (state.score1 == 0 && state.score2 == 0) {
      _feedback(NewMatchFeedback.noGoals);
      return;
    }
    if (state.score1 == state.score2) {
      _feedback(NewMatchFeedback.noWinner);
      return;
    }

    final snapshot = _MatchSnapshot.fromState(state);
    emit(state.copyWith(
      isSaving: true,
      clearLastFeedback: true,
      clearLastVictory: true,
    ));

    try {
      await _matchRepo.addMatch(
        mode: snapshot.mode,
        isRivalry: snapshot.isRivalry,
        team1: snapshot.team1,
        team2: snapshot.team2,
        score1: snapshot.score1,
        score2: snapshot.score2,
        scorerIds: snapshot.scorerIds,
      );
    } catch (_) {
      if (isClosed) return;
      final deferredPlayers = _deferredPlayers;
      _deferredPlayers = null;
      if (deferredPlayers != null) {
        _reconcilePlayers(
          deferredPlayers,
          isSaving: false,
          fallbackFeedback: NewMatchFeedback.saveFailed,
        );
      } else {
        _feedbackAfterSaveFailure();
      }
      return;
    }

    if (isClosed) return;

    emit(state.copyWith(
      isSaving: false,
      lastVictory: snapshot.victory(signalId: _nextSignal()),
    ));
  }

  void _feedbackAfterSaveFailure() {
    emit(state.copyWith(
      isSaving: false,
      lastFeedback: FeedbackEvent(
        kind: NewMatchFeedback.saveFailed,
        signalId: _nextSignal(),
      ),
    ));
  }

  void acknowledgeVictory() {
    if (state.isSaving) return;
    final players = _deferredPlayers ?? state.players;
    _deferredPlayers = null;
    emit(state.copyWith(
      players: players,
      assignment: const {},
      scorerIds: const [],
      score1: 0,
      score2: 0,
      kickedOff: false,
      clearLastGoal: true,
      clearLastVictory: true,
      clearLastFeedback: true,
    ));
  }

  void changeTeamsAfterVictory() {
    if (state.isSaving) return;
    final players = _deferredPlayers ?? state.players;
    _deferredPlayers = null;
    emit(state.copyWith(
      players: players,
      assignment: const {},
      scorerIds: const [],
      score1: 0,
      score2: 0,
      kickedOff: false,
      isRivalry: false,
      clearLastGoal: true,
      clearLastVictory: true,
      clearLastFeedback: true,
    ));
  }

  void rematchAfterVictory() {
    if (state.isSaving) return;
    final players = _deferredPlayers ?? state.players;
    _deferredPlayers = null;
    emit(state.copyWith(
      players: players,
      scorerIds: const [],
      score1: 0,
      score2: 0,
      kickedOff: true,
      clearLastGoal: true,
      clearLastVictory: true,
      clearLastFeedback: true,
    ));
  }

  @override
  Future<void> close() async {
    await _playersSub.cancel();
    await _matchesSub.cancel();
    return super.close();
  }
}

class _MatchSnapshot {
  const _MatchSnapshot({
    required this.mode,
    required this.isRivalry,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.scorerIds,
    required this.players,
  });

  factory _MatchSnapshot.fromState(NewMatchState state) {
    return _MatchSnapshot(
      mode: state.mode,
      isRivalry: state.isRivalry,
      team1: List.unmodifiable(state.team1),
      team2: List.unmodifiable(state.team2),
      score1: state.score1,
      score2: state.score2,
      scorerIds: List.unmodifiable(state.scorerIds),
      players: List.unmodifiable(state.players),
    );
  }

  final MatchMode mode;
  final bool isRivalry;
  final List<String> team1;
  final List<String> team2;
  final int score1;
  final int score2;
  final List<String> scorerIds;
  final List<Player> players;

  VictoryEvent victory({required int signalId}) {
    final firstTeamWon = score1 > score2;
    final winnerIds = firstTeamWon ? team1 : team2;
    return VictoryEvent(
      winningTeam: firstTeamWon ? 1 : 2,
      winnerIds: winnerIds,
      winnerNames: List.unmodifiable(
        winnerIds.map((id) => StatsService.playerName(players, id)),
      ),
      winnerScore: firstTeamWon ? score1 : score2,
      loserScore: firstTeamWon ? score2 : score1,
      signalId: signalId,
    );
  }
}
