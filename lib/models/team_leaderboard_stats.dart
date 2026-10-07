import 'package:equatable/equatable.dart';

import 'player.dart';
import 'ranking_stats.dart';
import 'player_badge.dart';

/// Aggregated ranking data for a recurring 2vs2 pair.
class TeamLeaderboardStats extends Equatable implements RankingStats {
  TeamLeaderboardStats({
    required this.id,
    required List<Player> players,
    required this.games,
    required this.wins,
    required this.losses,
    required this.goalsScored,
    this.currentWinStreak = 0,
    List<PlayerBadge> badges = const [],
  }) : players = List.unmodifiable(players),
       badges = List.unmodifiable(badges);

  @override
  final String id;
  final List<Player> players;
  @override
  final int games;
  @override
  final int wins;
  @override
  final int losses;
  @override
  final int goalsScored;
  @override
  final int currentWinStreak;
  @override
  final List<PlayerBadge> badges;

  @override
  String get name => players.map((player) => player.name).join(' + ');
  @override
  List<String> get memberNames =>
      players.map((p) => p.name).toList(growable: false);

  @override
  int get points => wins * 3;
  @override
  double get winRate => games == 0 ? 0 : wins / games;

  TeamLeaderboardStats copyWith({
    int? currentWinStreak,
    List<PlayerBadge>? badges,
  }) {
    return TeamLeaderboardStats(
      id: id,
      players: players,
      games: games,
      wins: wins,
      losses: losses,
      goalsScored: goalsScored,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      badges: badges ?? this.badges,
    );
  }

  @override
  List<Object?> get props => [
    id,
    players.map((player) => (player.id, player.name)).toList(growable: false),
    games,
    wins,
    losses,
    goalsScored,
    currentWinStreak,
    badges,
  ];
}
