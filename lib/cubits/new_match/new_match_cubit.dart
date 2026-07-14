import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        super(NewMatchState(players: playerRepository.players)) {
    _playersSub = _playerRepo.watchPlayers().listen(_onPlayersChanged);
  }

  final PlayerRepository _playerRepo;
  final MatchRepository _matchRepo;
  late final StreamSubscription<List<Player>> _playersSub;
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
      kickedOff: interruptedMatch ? false : null,
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
      if (targetTeam.length >= 2) return;
      current[playerId] = team;
    }
    emit(state.copyWith(assignment: Map.unmodifiable(current)));
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

  void addGoal(int team) {
    if (!state.kickedOff || state.isSaving || (team != 1 && team != 2)) return;
    if (team == 1) {
      emit(state.copyWith(
        score1: state.score1 + 1,
        lastGoal: GoalEvent(team: 1, signalId: _nextSignal()),
      ));
    } else if (team == 2) {
      emit(state.copyWith(
        score2: state.score2 + 1,
        lastGoal: GoalEvent(team: 2, signalId: _nextSignal()),
      ));
    }
  }

  void removeGoal(int team) {
    if (!state.kickedOff || state.isSaving) return;
    if (team == 1 && state.score1 > 0) {
      HapticFeedback.selectionClick();
      emit(state.copyWith(score1: state.score1 - 1));
    } else if (team == 2 && state.score2 > 0) {
      HapticFeedback.selectionClick();
      emit(state.copyWith(score2: state.score2 - 1));
    }
  }

  void setScore(int team, int value) {
    if (!state.kickedOff || state.isSaving || value < 0) return;
    if (team == 1) {
      emit(state.copyWith(score1: value));
    } else if (team == 2) {
      emit(state.copyWith(score2: value));
    }
  }

  void resetScore() {
    if (!state.kickedOff || state.isSaving) return;
    emit(state.copyWith(score1: 0, score2: 0));
  }

  void abortMatch() {
    if (state.isSaving) return;
    emit(state.copyWith(kickedOff: false, score1: 0, score2: 0));
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
        team1: snapshot.team1,
        team2: snapshot.team2,
        score1: snapshot.score1,
        score2: snapshot.score2,
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
      score1: 0,
      score2: 0,
      kickedOff: false,
      clearLastGoal: true,
      clearLastVictory: true,
      clearLastFeedback: true,
    ));
  }

  @override
  Future<void> close() async {
    await _playersSub.cancel();
    return super.close();
  }
}

class _MatchSnapshot {
  const _MatchSnapshot({
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.players,
  });

  factory _MatchSnapshot.fromState(NewMatchState state) {
    return _MatchSnapshot(
      team1: List.unmodifiable(state.team1),
      team2: List.unmodifiable(state.team2),
      score1: state.score1,
      score2: state.score2,
      players: List.unmodifiable(state.players),
    );
  }

  final List<String> team1;
  final List<String> team2;
  final int score1;
  final int score2;
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
