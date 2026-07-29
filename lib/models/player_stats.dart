import 'package:equatable/equatable.dart';

import 'player.dart';

class PlayerStats extends Equatable {
  final Player player;
  final int games;
  final int wins;
  final int losses;
  final int goalsScored;

  const PlayerStats({
    required this.player,
    required this.games,
    required this.wins,
    required this.losses,
    required this.goalsScored,
  });

  int get points => wins * 3;
  double get winRate => games == 0 ? 0 : wins / games;

  @override
  List<Object?> get props => [player.id, games, wins, losses, goalsScored];
}
