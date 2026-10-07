import 'package:equatable/equatable.dart';

import 'player.dart';
import 'player_badge.dart';

/// Aggregated ranking data for a recurring 2vs2 pair.
class TeamLeaderboardStats extends Equatable {
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

  final String id;
  final List<Player> players;
  final int games;
  final int wins;
  final int losses;
  final int goalsScored;
  final int currentWinStreak;
  final List<PlayerBadge> badges;

  String get name => players.map((player) => player.name).join(' + ');
  int get points => wins * 3;
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
