import '../models/game_match.dart';
import '../models/player.dart';
import '../models/player_badge.dart';
import '../models/player_profile_stats.dart';
import '../models/player_stats.dart';
import '../models/rivalry_overview.dart';

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
    return sortedByMostRecent(
      matches,
    ).where((m) => m.allPlayers.contains(playerId)).toList();
  }

  static PlayerProfileStats computePlayerProfile(
    List<GameMatch> matches,
    String playerId, {
    int recentLimit = 5,
  }) {
    final personalMatches = matchesForPlayer(matches, playerId);
    final teammateCounts = <String, int>{};
    final opponentCounts = <String, int>{};
    final opponentWins = <String, int>{};
    final teammateLastPlayedAt = <String, DateTime>{};
    final opponentLastPlayedAt = <String, DateTime>{};

    for (final match in personalMatches) {
      final playerTeam = match.team1.contains(playerId)
          ? match.team1
          : match.team2;
      final opponentTeam = match.team1.contains(playerId)
          ? match.team2
          : match.team1;
      for (final teammateId in playerTeam.where((id) => id != playerId)) {
        teammateCounts[teammateId] = (teammateCounts[teammateId] ?? 0) + 1;
        teammateLastPlayedAt.putIfAbsent(teammateId, () => match.playedAt);
      }
      for (final opponentId in opponentTeam) {
        opponentCounts[opponentId] = (opponentCounts[opponentId] ?? 0) + 1;
        opponentLastPlayedAt.putIfAbsent(opponentId, () => match.playedAt);
        if (match.winners.contains(playerId)) {
          opponentWins[opponentId] = (opponentWins[opponentId] ?? 0) + 1;
        }
      }
    }

    PlayerFrequency? mostFrequent(
      Map<String, int> counts,
      Map<String, DateTime> lastPlayedAt,
    ) {
      if (counts.isEmpty) return null;
      final entries = counts.entries.toList()
        ..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          if (byCount != 0) return byCount;
          final byRecency = lastPlayedAt[b.key]!.compareTo(
            lastPlayedAt[a.key]!,
          );
          return byRecency != 0 ? byRecency : a.key.compareTo(b.key);
        });
      return PlayerFrequency(
        playerId: entries.first.key,
        matches: entries.first.value,
      );
    }

    final headToHead =
        opponentCounts.entries.map((entry) {
          final wins = opponentWins[entry.key] ?? 0;
          return HeadToHeadStats(
            opponentId: entry.key,
            games: entry.value,
            wins: wins,
            losses: entry.value - wins,
          );
        }).toList()..sort((a, b) {
          final byGames = b.games.compareTo(a.games);
          return byGames != 0 ? byGames : a.opponentId.compareTo(b.opponentId);
        });

    return PlayerProfileStats(
      recentResults: List.unmodifiable(
        personalMatches
            .take(recentLimit)
            .map((match) => match.winners.contains(playerId)),
      ),
      mostFrequentTeammate: mostFrequent(teammateCounts, teammateLastPlayedAt),
      mostPlayedOpponent: mostFrequent(opponentCounts, opponentLastPlayedAt),
      headToHead: List.unmodifiable(headToHead),
    );
  }

  static RivalryOverview rivalryOverview(
    List<GameMatch> matches, {
    required List<String> team1Ids,
    required List<String> team2Ids,
  }) {
    var totalMatches = 0;
    var team1Wins = 0;
    var team2Wins = 0;
    var team1Goals = 0;
    var team2Goals = 0;
    final team1Set = team1Ids.toSet();
    final team2Set = team2Ids.toSet();

    for (final match in matches) {
      if (!match.isRivalry) {
        continue;
      }
      final aligned =
          match.team1.toSet().containsAll(team1Set) &&
          match.team2.toSet().containsAll(team2Set) &&
          match.team1.length == team1Ids.length &&
          match.team2.length == team2Ids.length;
      final swapped =
          match.team1.toSet().containsAll(team2Set) &&
          match.team2.toSet().containsAll(team1Set) &&
          match.team1.length == team2Ids.length &&
          match.team2.length == team1Ids.length;
      if (!aligned && !swapped) {
        continue;
      }

      totalMatches += 1;
      if (aligned) {
        team1Goals += _goalsForTeam(match, team1Ids);
        team2Goals += _goalsForTeam(match, team2Ids);
        if (match.winningTeam == 1) {
          team1Wins += 1;
        } else {
          team2Wins += 1;
        }
      } else {
        team1Goals += _goalsForTeam(match, team1Ids);
        team2Goals += _goalsForTeam(match, team2Ids);
        if (match.winningTeam == 1) {
          team2Wins += 1;
        } else {
          team1Wins += 1;
        }
      }
    }

    return RivalryOverview(
      team1Ids: List.unmodifiable(team1Ids),
      team2Ids: List.unmodifiable(team2Ids),
      totalMatches: totalMatches,
      team1Wins: team1Wins,
      team2Wins: team2Wins,
      team1Goals: team1Goals,
      team2Goals: team2Goals,
    );
  }

  static List<PlayerStats> computeLeaderboard(
    List<Player> players,
    List<GameMatch> matches,
  ) {
    final wins = <String, int>{};
    final games = <String, int>{};
    final goals = <String, int>{};
    final rivalryWins = <String, int>{};
    final currentWinStreak = <String, int>{};
    final streakClosed = <String>{};
    for (final p in players) {
      wins[p.id] = 0;
      games[p.id] = 0;
      goals[p.id] = 0;
      rivalryWins[p.id] = 0;
      currentWinStreak[p.id] = 0;
    }
    for (final m in matches) {
      for (final id in m.allPlayers) {
        games[id] = (games[id] ?? 0) + 1;
      }
      for (final id in m.winners) {
        wins[id] = (wins[id] ?? 0) + 1;
        if (m.isRivalry) {
          rivalryWins[id] = (rivalryWins[id] ?? 0) + 1;
        }
      }
      for (final scorerId in m.scorerIds) {
        goals[scorerId] = (goals[scorerId] ?? 0) + 1;
      }
    }
    for (final match in sortedByMostRecent(matches)) {
      for (final id in match.allPlayers) {
        if (streakClosed.contains(id)) {
          continue;
        }
        if (match.winners.contains(id)) {
          currentWinStreak[id] = (currentWinStreak[id] ?? 0) + 1;
        } else {
          streakClosed.add(id);
        }
      }
    }

    var list = players.map((p) {
      final g = games[p.id] ?? 0;
      final w = wins[p.id] ?? 0;
      return PlayerStats(
        player: p,
        games: g,
        wins: w,
        losses: g - w,
        goalsScored: goals[p.id] ?? 0,
        currentWinStreak: currentWinStreak[p.id] ?? 0,
      );
    }).toList();

    final topPoints = list.fold<int>(
      0,
      (max, stats) => stats.points > max ? stats.points : max,
    );
    final topGoals = list.fold<int>(
      0,
      (max, stats) => stats.goalsScored > max ? stats.goalsScored : max,
    );
    final topGames = list.fold<int>(
      0,
      (max, stats) => stats.games > max ? stats.games : max,
    );
    final topRivalryWins = rivalryWins.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );

    list = list.map((stats) {
      final badges = <PlayerBadge>[];
      if (stats.games > 0 && stats.points == topPoints && topPoints > 0) {
        badges.add(
          const PlayerBadge(
            code: 'leader',
            label: 'Capoclassifica',
            description: 'Ha il punteggio piu alto del ranking.',
          ),
        );
      }
      if (stats.goalsScored == topGoals && topGoals > 0) {
        badges.add(
          const PlayerBadge(
            code: 'bomber',
            label: 'Bomber',
            description: 'Miglior marcatore attuale.',
          ),
        );
      }
      if (stats.games == topGames && topGames >= 3) {
        badges.add(
          const PlayerBadge(
            code: 'grinder',
            label: 'Presenza Fissa',
            description:
                'E il giocatore piu presente nelle partite registrate.',
          ),
        );
      }
      if (stats.games >= 4 && stats.winRate >= 0.75) {
        badges.add(
          const PlayerBadge(
            code: 'dominant',
            label: 'Implacabile',
            description: 'Tiene un win rate alto su un campione credibile.',
          ),
        );
      }
      if (stats.currentWinStreak >= 3) {
        badges.add(
          PlayerBadge(
            code: 'streak',
            label: 'Hot Streak',
            description:
                'Ha una striscia aperta di ${stats.currentWinStreak} vittorie.',
          ),
        );
      }
      if ((rivalryWins[stats.player.id] ?? 0) == topRivalryWins &&
          topRivalryWins >= 2) {
        badges.add(
          const PlayerBadge(
            code: 'rivalry',
            label: 'Re delle Rivalita',
            description: 'Ha vinto piu duelli diretti in modalita Rivalita.',
          ),
        );
      }
      return stats.copyWith(badges: List.unmodifiable(badges));
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

  static int _goalsForTeam(GameMatch match, List<String> teamIds) {
    final teamSet = teamIds.toSet();
    return match.scorerIds.where(teamSet.contains).length;
  }
}
