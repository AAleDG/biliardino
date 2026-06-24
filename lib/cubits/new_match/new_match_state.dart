import 'package:equatable/equatable.dart';

import '../../models/player.dart';

enum NewMatchFeedback { noWinner, noGoals }

class GoalEvent extends Equatable {
  const GoalEvent({required this.team, required this.signalId});
  final int team;
  final int signalId;

  @override
  List<Object?> get props => [team, signalId];
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
  List<Object?> get props =>
      [winningTeam, winnerIds, winnerNames, winnerScore, loserScore, signalId];
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
    this.assignment = const {},
    this.score1 = 0,
    this.score2 = 0,
    this.kickedOff = false,
    this.lastGoal,
    this.lastVictory,
    this.lastFeedback,
  });

  final List<Player> players;
  final Map<String, int> assignment;
  final int score1;
  final int score2;
  final bool kickedOff;
  final GoalEvent? lastGoal;
  final VictoryEvent? lastVictory;
  final FeedbackEvent? lastFeedback;

  List<Player> get present => players.where((p) => p.isPresent).toList();

  List<String> team(int t) => assignment.entries
      .where((e) => e.value == t)
      .map((e) => e.key)
      .toList();

  List<String> get team1 => team(1);
  List<String> get team2 => team(2);

  bool get teamsValid => team1.length == 2 && team2.length == 2;
  bool get showScoreboard => teamsValid && kickedOff;

  NewMatchState copyWith({
    List<Player>? players,
    Map<String, int>? assignment,
    int? score1,
    int? score2,
    bool? kickedOff,
    GoalEvent? lastGoal,
    VictoryEvent? lastVictory,
    FeedbackEvent? lastFeedback,
  }) {
    return NewMatchState(
      players: players ?? this.players,
      assignment: assignment ?? this.assignment,
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      kickedOff: kickedOff ?? this.kickedOff,
      lastGoal: lastGoal ?? this.lastGoal,
      lastVictory: lastVictory ?? this.lastVictory,
      lastFeedback: lastFeedback ?? this.lastFeedback,
    );
  }

  @override
  List<Object?> get props => [
        players,
        assignment,
        score1,
        score2,
        kickedOff,
        lastGoal,
        lastVictory,
        lastFeedback,
      ];
}
