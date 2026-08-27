import 'package:equatable/equatable.dart';

class PlayerFrequency extends Equatable {
  const PlayerFrequency({required this.playerIds, required this.matches});

  final List<String> playerIds;
  final int matches;

  @override
  List<Object?> get props => [playerIds, matches];
}

class HeadToHeadStats extends Equatable {
  const HeadToHeadStats({
    required this.opponentId,
    required this.games,
    required this.wins,
    required this.losses,
  });

  final String opponentId;
  final int games;
  final int wins;
  final int losses;

  @override
  List<Object?> get props => [opponentId, games, wins, losses];
}

class PlayerProfileStats extends Equatable {
  const PlayerProfileStats({
    required this.recentResults,
    required this.mostFrequentTeammate,
    required this.mostPlayedOpponent,
    required this.headToHead,
  });

  final List<bool> recentResults;
  final PlayerFrequency? mostFrequentTeammate;
  final PlayerFrequency? mostPlayedOpponent;
  final List<HeadToHeadStats> headToHead;

  @override
  List<Object?> get props => [
    recentResults,
    mostFrequentTeammate,
    mostPlayedOpponent,
    headToHead,
  ];
}
