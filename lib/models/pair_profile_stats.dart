import 'game_match.dart';
import 'team_leaderboard_stats.dart';

class PairProfileStats {
  PairProfileStats({
    required this.stats,
    required this.rank,
    required List<GameMatch> matches,
    required List<bool> recentResults,
    required List<PairOpponentStats> opponents,
  }) : matches = List.unmodifiable(
         matches.map(
           (match) =>
               match.copyWith(scorerIds: List.unmodifiable(match.scorerIds)),
         ),
       ),
       recentResults = List.unmodifiable(recentResults),
       opponents = List.unmodifiable(opponents);

  final TeamLeaderboardStats stats;
  final int rank;
  final List<GameMatch> matches;
  final List<bool> recentResults;
  final List<PairOpponentStats> opponents;

  DateTime get togetherSince => matches.last.playedAt;
}

class PairOpponentStats {
  PairOpponentStats({
    required this.id,
    required List<String> playerIds,
    required this.games,
    required this.wins,
    required this.losses,
  }) : playerIds = List.unmodifiable(playerIds);

  final String id;
  final List<String> playerIds;
  final int games;
  final int wins;
  final int losses;
}
