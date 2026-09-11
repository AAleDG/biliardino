import 'package:equatable/equatable.dart';

import '../../models/player_stats.dart';

class LeaderboardState extends Equatable {
  final List<PlayerStats> stats;
  final bool isLoading;

  LeaderboardState({List<PlayerStats> stats = const [], this.isLoading = true})
    : stats = List.unmodifiable(stats);

  List<PlayerStats> get general =>
      List.unmodifiable(stats.where((s) => s.games > 0));

  List<PlayerStats> get scorers {
    final ranked = stats.where((s) => s.goalsScored > 0).toList()
      ..sort((a, b) {
        final goals = b.goalsScored.compareTo(a.goalsScored);
        if (goals != 0) return goals;
        final games = b.games.compareTo(a.games);
        if (games != 0) return games;
        return a.player.name.toLowerCase().compareTo(
          b.player.name.toLowerCase(),
        );
      });
    return List.unmodifiable(ranked);
  }

  LeaderboardState copyWith({List<PlayerStats>? stats, bool? isLoading}) {
    return LeaderboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [stats, isLoading];
}
