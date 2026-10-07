import 'package:equatable/equatable.dart';

import 'player.dart';
import 'ranking_stats.dart';
import 'player_badge.dart';

class PlayerStats extends Equatable implements RankingStats {
  final Player player;
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

  PlayerStats({
    required this.player,
    required this.games,
    required this.wins,
    required this.losses,
    required this.goalsScored,
    this.currentWinStreak = 0,
    List<PlayerBadge> badges = const [],
  }) : badges = List.unmodifiable(badges);

  @override
  String get id => player.id;
  @override
  String get name => player.name;
  @override
  List<String> get memberNames => [player.name];

  @override
  int get points => wins * 3;
  @override
  double get winRate => games == 0 ? 0 : wins / games;

  PlayerStats copyWith({int? currentWinStreak, List<PlayerBadge>? badges}) {
    return PlayerStats(
      player: player,
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
    player.id,
    player.name,
    games,
    wins,
    losses,
    goalsScored,
    currentWinStreak,
    badges,
  ];
}
