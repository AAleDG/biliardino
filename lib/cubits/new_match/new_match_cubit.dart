import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/game_match.dart';
import '../../models/match_rules.dart';
import '../../models/player.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/match_rules_repository.dart';
import '../../repositories/player_repository.dart';
import '../../services/stats_service.dart';
import 'new_match_state.dart';

class NewMatchCubit extends Cubit<NewMatchState> {
  NewMatchCubit({
    required PlayerRepository playerRepository,
    required MatchRepository matchRepository,
    required MatchRulesRepository matchRulesRepository,
    Random? random,
  }) : _playerRepo = playerRepository,
       _matchRepo = matchRepository,
       _rulesRepo = matchRulesRepository,
       _random = random ?? Random(),
       super(
         NewMatchState(
           players: playerRepository.players,
           matches: matchRepository.matches,
           rules: matchRulesRepository.rules,
         ),
       ) {
    _playersSub = _playerRepo.watchPlayers().listen(_onPlayersChanged);
    _matchesSub = _matchRepo.watchMatches().listen(_onMatchesChanged);
  }

  final PlayerRepository _playerRepo;
  final MatchRepository _matchRepo;
  final MatchRulesRepository _rulesRepo;
  final Random _random;
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

    emit(
      state.copyWith(
        players: players,
        assignment: assignment,
        isRivalry: invalidated ? false : state.isRivalry,
        kickedOff: interruptedMatch ? false : null,
        scorerIds: interruptedMatch ? const [] : null,
        score1: interruptedMatch ? 0 : null,
        score2: interruptedMatch ? 0 : null,
        clearPendingVictory: interruptedMatch,
        isSaving: isSaving,
        lastFeedback: feedbackKind != null
            ? FeedbackEvent(kind: feedbackKind, signalId: _nextSignal())
            : state.lastFeedback,
      ),
    );
  }

  void _feedback(NewMatchFeedback kind) {
    emit(
      state.copyWith(
        lastFeedback: FeedbackEvent(kind: kind, signalId: _nextSignal()),
      ),
    );
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
    emit(
      state.copyWith(assignment: Map.unmodifiable(current), isRivalry: false),
    );
  }

  void generateRandomTeams() {
    _generateTeams(balanced: false);
  }

  void generateBalancedTeams() {
    _generateTeams(balanced: true);
  }

  void _generateTeams({required bool balanced}) {
    if (state.kickedOff || state.isSaving || state.isPersistingRules) return;
    if (state.present.length < state.requiredPlayers) return;

    final eligibleIds = state.present.map((player) => player.id).toList();
    late List<Map<String, int>> candidates;

    if (balanced) {
      candidates = _playerCombinations(
        eligibleIds,
        state.requiredPlayers,
      ).expand((ids) => _teamAssignments(ids, state.mode.teamSize)).toList();
      final pointsByPlayer = {
        for (final stats in StatsService.computeLeaderboard(
          state.players,
          state.matches,
        ))
          stats.player.id: stats.points,
      };
      var smallestDifference = 1 << 62;
      final balancedCandidates = <Map<String, int>>[];
      for (final candidate in candidates) {
        var team1Points = 0;
        var team2Points = 0;
        for (final entry in candidate.entries) {
          final points = pointsByPlayer[entry.key] ?? 0;
          if (entry.value == 1) {
            team1Points += points;
          } else {
            team2Points += points;
          }
        }
        final difference = (team1Points - team2Points).abs();
        if (difference < smallestDifference) {
          smallestDifference = difference;
          balancedCandidates
            ..clear()
            ..add(candidate);
        } else if (difference == smallestDifference) {
          balancedCandidates.add(candidate);
        }
      }
      candidates = balancedCandidates;
    } else {
      _shuffle(eligibleIds);
      final selectedIds = eligibleIds.take(state.requiredPlayers).toList();
      candidates = _teamAssignments(selectedIds, state.mode.teamSize);
    }

    final alternatives = candidates
        .where((candidate) => !_sameAssignment(candidate, state.assignment))
        .toList();
    final proposals = alternatives.isNotEmpty ? alternatives : candidates;
    final assignment = proposals[_random.nextInt(proposals.length)];
    emit(
      state.copyWith(
        assignment: Map.unmodifiable(assignment),
        isRivalry: false,
      ),
    );
  }

  void _shuffle(List<String> values) {
    for (var index = values.length - 1; index > 0; index--) {
      final swapIndex = _random.nextInt(index + 1);
      final value = values[index];
      values[index] = values[swapIndex];
      values[swapIndex] = value;
    }
  }

  static List<Map<String, int>> _teamAssignments(
    List<String> playerIds,
    int teamSize,
  ) {
    final assignments = <Map<String, int>>[];

    void chooseTeam1(int start, List<String> team1) {
      if (team1.length == teamSize) {
        final team1Ids = team1.toSet();
        assignments.add({
          for (final id in playerIds) id: team1Ids.contains(id) ? 1 : 2,
        });
        return;
      }
      final remaining = teamSize - team1.length;
      for (var index = start; index <= playerIds.length - remaining; index++) {
        chooseTeam1(index + 1, [...team1, playerIds[index]]);
      }
    }

    chooseTeam1(0, const []);
    return assignments;
  }

  static List<List<String>> _playerCombinations(
    List<String> playerIds,
    int requiredPlayers,
  ) {
    final combinations = <List<String>>[];

    void choosePlayers(int start, List<String> selected) {
      if (selected.length == requiredPlayers) {
        combinations.add(List.unmodifiable(selected));
        return;
      }
      final remaining = requiredPlayers - selected.length;
      for (var index = start; index <= playerIds.length - remaining; index++) {
        choosePlayers(index + 1, [...selected, playerIds[index]]);
      }
    }

    choosePlayers(0, const []);
    return combinations;
  }

  static bool _sameAssignment(Map<String, int> first, Map<String, int> second) {
    if (first.length != second.length) return false;
    return first.entries.every((entry) => second[entry.key] == entry.value);
  }

  void setMatchMode(MatchMode mode) {
    if (state.kickedOff ||
        state.isSaving ||
        state.isPersistingRules ||
        state.mode == mode) {
      return;
    }
    emit(
      state.copyWith(
        mode: mode,
        isRivalry: false,
        assignment: const {},
        scorerIds: const [],
        score1: 0,
        score2: 0,
        clearLastGoal: true,
        clearLastFeedback: true,
      ),
    );
  }

  Future<void> setRuleMode(MatchRuleMode mode) async {
    if (state.kickedOff ||
        state.isSaving ||
        state.isPersistingRules ||
        state.rules.mode == mode) {
      return;
    }
    await _setRules(state.rules.copyWith(mode: mode));
  }

  Future<void> setTargetScore(int targetScore) async {
    if (state.kickedOff || state.isSaving || state.isPersistingRules) return;
    await _setRules(state.rules.copyWith(targetScore: targetScore));
  }

  Future<void> setWinByTwo(bool enabled) async {
    if (state.kickedOff ||
        state.isSaving ||
        state.isPersistingRules ||
        state.rules.winByTwo == enabled) {
      return;
    }
    await _setRules(state.rules.copyWith(winByTwo: enabled));
  }

  Future<void> _setRules(MatchRules rules) async {
    final previousRules = state.rules;
    emit(
      state.copyWith(
        rules: rules,
        isPersistingRules: true,
        clearLastFeedback: true,
      ),
    );
    try {
      await _rulesRepo.save(rules);
    } on Object {
      if (isClosed) return;
      emit(
        state.copyWith(
          rules: previousRules,
          isPersistingRules: false,
          lastFeedback: FeedbackEvent(
            kind: NewMatchFeedback.saveFailed,
            signalId: _nextSignal(),
          ),
        ),
      );
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(isPersistingRules: false));
  }

  void setRivalry(bool enabled) {
    if (state.kickedOff ||
        state.isSaving ||
        state.isPersistingRules ||
        !state.teamsValid) {
      return;
    }
    emit(state.copyWith(isRivalry: enabled));
  }

  void kickoff() {
    if (state.isSaving || state.isPersistingRules || state.kickedOff) return;
    if (!state.teamsValid) {
      _feedback(NewMatchFeedback.invalidTeams);
      return;
    }
    HapticFeedback.mediumImpact();
    emit(
      state.copyWith(
        kickedOff: true,
        score1: 0,
        score2: 0,
        clearPendingVictory: true,
      ),
    );
  }

  void addGoal(int team, String scorerId) {
    if (!state.kickedOff ||
        state.isSaving ||
        state.pendingVictory != null ||
        (team != 1 && team != 2)) {
      return;
    }
    final teamPlayers = state.team(team);
    if (!teamPlayers.contains(scorerId)) return;

    final scorerName = StatsService.playerName(state.players, scorerId);
    final scorerIds = List<String>.from(state.scorerIds)..add(scorerId);

    final score1 = team == 1 ? state.score1 + 1 : state.score1;
    final score2 = team == 2 ? state.score2 + 1 : state.score2;
    final winner = state.rules.winningTeam(score1: score1, score2: score2);
    final pendingVictory = winner == null
        ? null
        : _MatchSnapshot.fromState(
            state.copyWith(
              scorerIds: List.unmodifiable(scorerIds),
              score1: score1,
              score2: score2,
            ),
          ).victory(signalId: _nextSignal());

    if (team == 1) {
      emit(
        state.copyWith(
          scorerIds: List.unmodifiable(scorerIds),
          score1: score1,
          pendingVictory: pendingVictory,
          lastGoal: GoalEvent(
            team: 1,
            scorerId: scorerId,
            scorerName: scorerName,
            signalId: _nextSignal(),
          ),
        ),
      );
    } else if (team == 2) {
      emit(
        state.copyWith(
          scorerIds: List.unmodifiable(scorerIds),
          score2: score2,
          pendingVictory: pendingVictory,
          lastGoal: GoalEvent(
            team: 2,
            scorerId: scorerId,
            scorerName: scorerName,
            signalId: _nextSignal(),
          ),
        ),
      );
    }
  }

  void removeGoal(int team) {
    if (!state.kickedOff || state.isSaving || state.pendingVictory != null) {
      return;
    }
    final teamPlayers = state.team(team).toSet();
    if (teamPlayers.isEmpty) return;

    final scorerIds = List<String>.from(state.scorerIds);
    final removeIndex = scorerIds.lastIndexWhere(teamPlayers.contains);
    if (removeIndex == -1) return;

    scorerIds.removeAt(removeIndex);
    HapticFeedback.selectionClick();
    if (team == 1 && state.score1 > 0) {
      emit(
        state.copyWith(
          scorerIds: List.unmodifiable(scorerIds),
          score1: state.score1 - 1,
        ),
      );
    } else if (team == 2 && state.score2 > 0) {
      emit(
        state.copyWith(
          scorerIds: List.unmodifiable(scorerIds),
          score2: state.score2 - 1,
        ),
      );
    }
  }

  void resetScore() {
    if (!state.kickedOff || state.isSaving) return;
    emit(
      state.copyWith(
        score1: 0,
        score2: 0,
        scorerIds: const [],
        clearPendingVictory: true,
      ),
    );
  }

  void abortMatch() {
    if (state.isSaving) return;
    emit(
      state.copyWith(
        kickedOff: false,
        scorerIds: const [],
        score1: 0,
        score2: 0,
        clearPendingVictory: true,
      ),
    );
  }

  void correctScoreBeforeConfirmation() {
    if (state.isSaving || state.pendingVictory == null) return;
    emit(state.copyWith(clearPendingVictory: true));
  }

  Future<void> confirmAndSaveCompletedMatch() async {
    if (state.pendingVictory == null) return;
    await save(confirmedCompletion: true);
  }

  Future<void> save({bool confirmedCompletion = false}) async {
    if (state.isSaving || state.lastVictory != null) return;
    if (state.pendingVictory != null && !confirmedCompletion) return;
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
    emit(
      state.copyWith(
        isSaving: true,
        clearPendingVictory: true,
        clearLastFeedback: true,
        clearLastVictory: true,
      ),
    );

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
    } on Object {
      if (isClosed) return;
      final deferredPlayers = _deferredPlayers;
      _deferredPlayers = null;
      final pendingVictory = confirmedCompletion
          ? snapshot.victory(signalId: _nextSignal())
          : null;
      if (deferredPlayers != null) {
        _reconcilePlayers(
          deferredPlayers,
          isSaving: false,
          fallbackFeedback: NewMatchFeedback.saveFailed,
        );
        if (pendingVictory != null && state.kickedOff) {
          emit(state.copyWith(pendingVictory: pendingVictory));
        }
      } else {
        _feedbackAfterSaveFailure(pendingVictory: pendingVictory);
      }
      return;
    }

    if (isClosed) return;

    emit(
      state.copyWith(
        isSaving: false,
        lastVictory: snapshot.victory(signalId: _nextSignal()),
      ),
    );
  }

  void _feedbackAfterSaveFailure({VictoryEvent? pendingVictory}) {
    emit(
      state.copyWith(
        isSaving: false,
        pendingVictory: pendingVictory,
        lastFeedback: FeedbackEvent(
          kind: NewMatchFeedback.saveFailed,
          signalId: _nextSignal(),
        ),
      ),
    );
  }

  void acknowledgeVictory() {
    if (state.isSaving || state.lastVictory == null) return;
    final players = _deferredPlayers ?? state.players;
    _deferredPlayers = null;
    emit(
      state.copyWith(
        players: players,
        assignment: const {},
        scorerIds: const [],
        score1: 0,
        score2: 0,
        kickedOff: false,
        clearPendingVictory: true,
        clearLastGoal: true,
        clearLastVictory: true,
        clearLastFeedback: true,
      ),
    );
  }

  void changeTeamsAfterVictory() {
    if (state.isSaving) return;
    final players = _deferredPlayers ?? state.players;
    _deferredPlayers = null;
    emit(
      state.copyWith(
        players: players,
        assignment: const {},
        scorerIds: const [],
        score1: 0,
        score2: 0,
        kickedOff: false,
        isRivalry: false,
        clearPendingVictory: true,
        clearLastGoal: true,
        clearLastVictory: true,
        clearLastFeedback: true,
      ),
    );
  }

  void rematchAfterVictory() {
    if (state.isSaving) return;
    final players = _deferredPlayers ?? state.players;
    _deferredPlayers = null;
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
    final teamsValid =
        assignment.values.where((team) => team == 1).length ==
            state.mode.teamSize &&
        assignment.values.where((team) => team == 2).length ==
            state.mode.teamSize;
    emit(
      state.copyWith(
        players: players,
        assignment: assignment,
        scorerIds: const [],
        score1: 0,
        score2: 0,
        kickedOff: teamsValid,
        isRivalry: teamsValid ? null : false,
        clearPendingVictory: true,
        clearLastGoal: true,
        clearLastVictory: true,
        lastFeedback: teamsValid
            ? null
            : FeedbackEvent(
                kind: NewMatchFeedback.playersUnavailable,
                signalId: _nextSignal(),
              ),
        clearLastFeedback: teamsValid,
      ),
    );
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
