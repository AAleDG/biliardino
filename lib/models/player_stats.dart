import 'package:equatable/equatable.dart';

import 'player.dart';
import 'player_badge.dart';

class PlayerStats extends Equatable {
  final Player player;
  final int games;
  final int wins;
  final int losses;
  final int goalsScored;
  final int currentWinStreak;
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

  int get points => wins * 3;
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
