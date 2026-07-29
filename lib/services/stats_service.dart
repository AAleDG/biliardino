import '../models/game_match.dart';
import '../models/player.dart';
import '../models/player_stats.dart';

class StatsService {
  const StatsService._();

  static String playerName(List<Player> players, String id) {
    for (final p in players) {
      if (p.id == id) return p.name;
    }
    return '—';
  }

  static List<GameMatch> sortedByMostRecent(List<GameMatch> matches) {
    return [...matches]..sort((a, b) => b.playedAt.compareTo(a.playedAt));
  }

  static List<GameMatch> matchesForPlayer(
    List<GameMatch> matches,
    String playerId,
  ) {
    return sortedByMostRecent(matches)
        .where((m) => m.allPlayers.contains(playerId))
        .toList();
  }

  static List<PlayerStats> computeLeaderboard(
    List<Player> players,
    List<GameMatch> matches,
  ) {
    final wins = <String, int>{};
    final games = <String, int>{};
    final goals = <String, int>{};
    for (final p in players) {
      wins[p.id] = 0;
      games[p.id] = 0;
      goals[p.id] = 0;
    }
    for (final m in matches) {
      for (final id in m.allPlayers) {
        games[id] = (games[id] ?? 0) + 1;
      }
      for (final id in m.winners) {
        wins[id] = (wins[id] ?? 0) + 1;
      }
      for (final scorerId in m.scorerIds) {
        goals[scorerId] = (goals[scorerId] ?? 0) + 1;
      }
    }
    final list = players.map((p) {
      final g = games[p.id] ?? 0;
      final w = wins[p.id] ?? 0;
      return PlayerStats(
        player: p,
        games: g,
        wins: w,
        losses: g - w,
        goalsScored: goals[p.id] ?? 0,
      );
    }).toList();

    list.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      final byRate = b.winRate.compareTo(a.winRate);
      if (byRate != 0) return byRate;
      return a.player.name.toLowerCase().compareTo(b.player.name.toLowerCase());
    });
    return list;
  }
}
