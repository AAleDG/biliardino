import 'package:equatable/equatable.dart';

import '../../models/player_stats.dart';

class LeaderboardState extends Equatable {
  final List<PlayerStats> stats;
  final bool isLoading;

  const LeaderboardState({
    this.stats = const [],
    this.isLoading = true,
  });

  LeaderboardState copyWith({List<PlayerStats>? stats, bool? isLoading}) {
    return LeaderboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [stats, isLoading];
}
