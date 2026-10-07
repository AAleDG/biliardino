import 'package:equatable/equatable.dart';

import '../../models/game_match.dart';
import '../../models/player_stats.dart';
import '../../models/team_leaderboard_stats.dart';

class LeaderboardState extends Equatable {
  LeaderboardState({
    List<PlayerStats> stats = const [],
    List<TeamLeaderboardStats> teams = const [],
    this.selectedMode = MatchMode.oneVsOne,
    this.isLoading = true,
  }) : stats = List.unmodifiable(stats),
       teams = List.unmodifiable(teams);

  final List<PlayerStats> stats;
  final List<TeamLeaderboardStats> teams;
  final MatchMode selectedMode;
  final bool isLoading;

  List<PlayerStats> get general =>
      List.unmodifiable(stats.where((stat) => stat.games > 0));

  List<PlayerStats> get scorers {
    final ranked = stats.where((stat) => stat.goalsScored > 0).toList();
    ranked.sort((first, second) {
      final byGoals = second.goalsScored.compareTo(first.goalsScored);
      if (byGoals != 0) return byGoals;
      final byGames = second.games.compareTo(first.games);
      if (byGames != 0) return byGames;
      return first.player.name.toLowerCase().compareTo(
        second.player.name.toLowerCase(),
      );
    });
    return List.unmodifiable(ranked);
  }

  List<TeamLeaderboardStats> get teamGeneral =>
      List.unmodifiable(teams.where((team) => team.games > 0));

  List<TeamLeaderboardStats> get teamScorers {
    final ranked = teams.where((team) => team.goalsScored > 0).toList();
    ranked.sort((first, second) {
      final byGoals = second.goalsScored.compareTo(first.goalsScored);
      if (byGoals != 0) return byGoals;
      final byGames = second.games.compareTo(first.games);
      if (byGames != 0) return byGames;
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });
    return List.unmodifiable(ranked);
  }

  LeaderboardState copyWith({
    List<PlayerStats>? stats,
    List<TeamLeaderboardStats>? teams,
    MatchMode? selectedMode,
    bool? isLoading,
  }) {
    return LeaderboardState(
      stats: stats ?? this.stats,
      teams: teams ?? this.teams,
      selectedMode: selectedMode ?? this.selectedMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [stats, teams, selectedMode, isLoading];
}
