import 'package:equatable/equatable.dart';

import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../models/player_profile_stats.dart';
import '../../models/player_stats.dart';

class PlayerProfileState extends Equatable {
  PlayerProfileState({
    required List<Player> players,
    required this.stats,
    required PlayerProfileStats profile,
    required List<GameMatch> personalMatches,
  }) : players = List.unmodifiable(players),
       profile = PlayerProfileStats(
         recentResults: List.unmodifiable(profile.recentResults),
         mostFrequentTeammate: _snapshot(profile.mostFrequentTeammate),
         mostPlayedOpponent: _snapshot(profile.mostPlayedOpponent),
         headToHead: List.unmodifiable(profile.headToHead),
       ),
       personalMatches = List.unmodifiable(
         personalMatches.map(
           (match) =>
               match.copyWith(scorerIds: List.unmodifiable(match.scorerIds)),
         ),
       );

  final List<Player> players;
  final PlayerStats? stats;
  final PlayerProfileStats profile;
  final List<GameMatch> personalMatches;

  Player? get player => stats?.player;

  static PlayerFrequency? _snapshot(PlayerFrequency? frequency) =>
      frequency == null
      ? null
      : PlayerFrequency(
          playerIds: List.unmodifiable(frequency.playerIds),
          matches: frequency.matches,
        );

  @override
  List<Object?> get props => [
    stats,
    player?.isPresent,
    player?.isArchived,
    players,
    profile,
    personalMatches,
  ];
}
