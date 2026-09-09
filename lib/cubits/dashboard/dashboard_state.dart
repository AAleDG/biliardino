import 'package:equatable/equatable.dart';

import '../../models/game_match.dart';
import '../../models/player_stats.dart';

class DashboardMatchSummary extends Equatable {
  const DashboardMatchSummary({
    required this.match,
    required this.teamOneName,
    required this.teamTwoName,
  });

  final GameMatch match;
  final String teamOneName;
  final String teamTwoName;

  @override
  List<Object?> get props => [
    match.id,
    match.playedAt,
    match.mode,
    match.team1,
    match.team2,
    match.t1Score,
    match.t2Score,
    match.winningTeam,
    match.scorerIds,
    match.isRivalry,
    teamOneName,
    teamTwoName,
  ];
}

class DashboardState extends Equatable {
  const DashboardState({
    this.recentMatches = const [],
    this.ranking = const [],
    this.isLoading = true,
  });

  final List<DashboardMatchSummary> recentMatches;
  final List<PlayerStats> ranking;
  final bool isLoading;

  @override
  List<Object?> get props => [recentMatches, ranking, isLoading];
}
