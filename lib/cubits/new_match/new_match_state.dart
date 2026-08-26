import 'package:equatable/equatable.dart';

import '../../models/game_match.dart';
import '../../models/match_rules.dart';
import '../../models/player.dart';

enum NewMatchFeedback {
  noWinner,
  noGoals,
  invalidTeams,
  saveFailed,
  playersUnavailable,
}

class GoalEvent extends Equatable {
  const GoalEvent({
    required this.team,
    required this.scorerId,
    required this.scorerName,
    required this.signalId,
  });

  final int team;
  final String scorerId;
  final String scorerName;
  final int signalId;

  @override
  List<Object?> get props => [team, scorerId, scorerName, signalId];
}

class VictoryEvent extends Equatable {
  const VictoryEvent({
    required this.winningTeam,
    required this.winnerIds,
    required this.winnerNames,
    required this.winnerScore,
    required this.loserScore,
    required this.signalId,
  });

  final int winningTeam;
  final List<String> winnerIds;
  final List<String> winnerNames;
  final int winnerScore;
  final int loserScore;
  final int signalId;

  @override
  List<Object?> get props => [
    winningTeam,
    winnerIds,
    winnerNames,
    winnerScore,
    loserScore,
    signalId,
  ];
}

class FeedbackEvent extends Equatable {
  const FeedbackEvent({required this.kind, required this.signalId});
  final NewMatchFeedback kind;
  final int signalId;

  @override
  List<Object?> get props => [kind, signalId];
}

class NewMatchState extends Equatable {
  const NewMatchState({
    this.players = const [],
    this.matches = const [],
    this.mode = MatchMode.twoVsTwo,
    this.rules = MatchRules.defaultRules,
    this.isRivalry = false,
    this.assignment = const {},
    this.scorerIds = const [],
    this.score1 = 0,
    this.score2 = 0,
    this.kickedOff = false,
    this.isSaving = false,
    this.lastGoal,
    this.pendingVictory,
    this.lastVictory,
    this.lastFeedback,
  });

  final List<Player> players;
  final List<GameMatch> matches;
  final MatchMode mode;
  final MatchRules rules;
  final bool isRivalry;
  final Map<String, int> assignment;
  final List<String> scorerIds;
  final int score1;
  final int score2;
  final bool kickedOff;
  final bool isSaving;
  final GoalEvent? lastGoal;
  final VictoryEvent? pendingVictory;
  final VictoryEvent? lastVictory;
  final FeedbackEvent? lastFeedback;

  List<Player> get present =>
      List.unmodifiable(players.where((p) => p.isPresent));

  List<String> team(int t) =>
      assignment.entries.where((e) => e.value == t).map((e) => e.key).toList();

  List<String> get team1 => team(1);
  List<String> get team2 => team(2);
  int get requiredPlayers => mode.teamSize * 2;

  bool get teamsValid {
    final firstTeam = team1;
    final secondTeam = team2;
    final selected = {...firstTeam, ...secondTeam};
    final presentIds = present.map((player) => player.id).toSet();
    return firstTeam.length == mode.teamSize &&
        secondTeam.length == mode.teamSize &&
        selected.length == requiredPlayers &&
        selected.every(presentIds.contains);
  }

  bool get showScoreboard => teamsValid && kickedOff;

  NewMatchState copyWith({
    List<Player>? players,
    List<GameMatch>? matches,
    MatchMode? mode,
    MatchRules? rules,
    bool? isRivalry,
    Map<String, int>? assignment,
    List<String>? scorerIds,
    int? score1,
    int? score2,
    bool? kickedOff,
    bool? isSaving,
    GoalEvent? lastGoal,
    VictoryEvent? pendingVictory,
    VictoryEvent? lastVictory,
    FeedbackEvent? lastFeedback,
    bool clearLastGoal = false,
    bool clearPendingVictory = false,
    bool clearLastVictory = false,
    bool clearLastFeedback = false,
  }) {
    return NewMatchState(
      players: players ?? this.players,
      matches: matches ?? this.matches,
      mode: mode ?? this.mode,
      rules: rules ?? this.rules,
      isRivalry: isRivalry ?? this.isRivalry,
      assignment: assignment ?? this.assignment,
      scorerIds: scorerIds ?? this.scorerIds,
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      kickedOff: kickedOff ?? this.kickedOff,
      isSaving: isSaving ?? this.isSaving,
      lastGoal: clearLastGoal ? null : lastGoal ?? this.lastGoal,
      pendingVictory: clearPendingVictory
          ? null
          : pendingVictory ?? this.pendingVictory,
      lastVictory: clearLastVictory ? null : lastVictory ?? this.lastVictory,
      lastFeedback: clearLastFeedback
          ? null
          : lastFeedback ?? this.lastFeedback,
    );
  }

  @override
  List<Object?> get props => [
    players,
    matches,
    mode,
    rules,
    isRivalry,
    assignment,
    scorerIds,
    score1,
    score2,
    kickedOff,
    isSaving,
    lastGoal,
    pendingVictory,
    lastVictory,
    lastFeedback,
  ];
}
