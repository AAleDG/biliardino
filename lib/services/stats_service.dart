import 'dart:convert';

import '../models/game_match.dart';
import '../models/player.dart';
import '../models/pair_profile_stats.dart';
import '../models/team_leaderboard_stats.dart';
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
  }) => playerHistory(matches, playerId, recentLimit: recentLimit).profile;

  /// Derives both profile sections from one chronologically ordered history.
  static ({List<GameMatch> matches, PlayerProfileStats profile}) playerHistory(
    List<GameMatch> matches,
    String playerId, {
    int recentLimit = 5,
  }) {
    final personalMatches = matchesForPlayer(matches, playerId);
    return (
      matches: List.unmodifiable(personalMatches),
      profile: _profileFromHistory(personalMatches, playerId, recentLimit),
    );
  }

  static PlayerProfileStats _profileFromHistory(
    List<GameMatch> personalMatches,
    String playerId,
    int recentLimit,
  ) {
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
      final highestCount = counts.values.reduce((a, b) => a > b ? a : b);
      final mostRecent = counts.entries
          .where((entry) => entry.value == highestCount)
          .map((entry) => lastPlayedAt[entry.key]!)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final playerIds = counts.entries
          .where(
            (entry) =>
                entry.value == highestCount &&
                lastPlayedAt[entry.key] == mostRecent,
          )
          .map((entry) => entry.key)
          .toList(growable: false);
      return PlayerFrequency(
        playerIds: List.unmodifiable(playerIds),
        matches: highestCount,
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

  static List<TeamLeaderboardStats> computeTeamLeaderboard(
    List<Player> players,
    List<GameMatch> matches,
  ) {
    final playersById = <String, Player>{
      for (final player in players) player.id: player,
    };
    final twoVsTwoMatches = matches
        .where((match) => match.mode == MatchMode.twoVsTwo)
        .toList(growable: false);
    final accumulators = <String, _TeamAccumulator>{};

    for (final match in twoVsTwoMatches) {
      _recordTeam(
        accumulators: accumulators,
        playerIds: match.team1,
        won: match.winningTeam == 1,
        goals: _goalsForTeam(match, match.team1),
      );
      _recordTeam(
        accumulators: accumulators,
        playerIds: match.team2,
        won: match.winningTeam == 2,
        goals: _goalsForTeam(match, match.team2),
      );
    }

    final closedStreaks = <String>{};
    for (final match in sortedByMostRecent(twoVsTwoMatches)) {
      final winningTeam = match.winningTeam == 1 ? match.team1 : match.team2;
      for (final team in [match.team1, match.team2]) {
        final key = _teamKey(team);
        if (closedStreaks.contains(key)) continue;
        if (winningTeam.toSet().containsAll(team)) {
          accumulators[key]?.currentWinStreak += 1;
        } else {
          closedStreaks.add(key);
        }
      }
    }

    final teams = accumulators.values
        .map((accumulator) {
          final teamPlayers =
              accumulator.playerIds
                  .map((id) => playersById[id])
                  .whereType<Player>()
                  .toList()
                ..sort(
                  (first, second) => first.name.toLowerCase().compareTo(
                    second.name.toLowerCase(),
                  ),
                );
          return TeamLeaderboardStats(
            id: accumulator.id,
            players: List.unmodifiable(teamPlayers),
            games: accumulator.games,
            wins: accumulator.wins,
            losses: accumulator.losses,
            goalsScored: accumulator.goalsScored,
            currentWinStreak: accumulator.currentWinStreak,
          );
        })
        .where((team) => team.players.length == 2)
        .toList();

    final topPoints = teams.fold<int>(
      0,
      (max, stats) => stats.points > max ? stats.points : max,
    );
    final topGoals = teams.fold<int>(
      0,
      (max, stats) => stats.goalsScored > max ? stats.goalsScored : max,
    );
    final topGames = teams.fold<int>(
      0,
      (max, stats) => stats.games > max ? stats.games : max,
    );

    final decorated = teams.map((stats) {
      final badges = <PlayerBadge>[];
      if (stats.points == topPoints && topPoints > 0) {
        badges.add(
          const PlayerBadge(
            code: 'leader',
            label: 'Capoclassifica',
            description: 'Ha il punteggio piu alto del ranking di coppia.',
          ),
        );
      }
      if (stats.goalsScored == topGoals && topGoals > 0) {
        badges.add(
          const PlayerBadge(
            code: 'bomber',
            label: 'Bomber',
            description: 'Ha segnato piu gol nella classifica 2vs2.',
          ),
        );
      }
      if (stats.games == topGames && topGames >= 3) {
        badges.add(
          const PlayerBadge(
            code: 'grinder',
            label: 'Presenza Fissa',
            description: 'E la coppia piu presente nelle partite 2vs2.',
          ),
        );
      }
      return stats.copyWith(badges: List.unmodifiable(badges));
    }).toList();

    decorated.sort((first, second) {
      final byPoints = second.points.compareTo(first.points);
      if (byPoints != 0) return byPoints;
      final byRate = second.winRate.compareTo(first.winRate);
      if (byRate != 0) return byRate;
      final byName = first.name.toLowerCase().compareTo(
        second.name.toLowerCase(),
      );
      return byName != 0 ? byName : first.id.compareTo(second.id);
    });
    return List.unmodifiable(decorated);
  }

  static PairProfileStats? computePairProfile(
    List<Player> players,
    List<GameMatch> matches,
    String pairId,
  ) {
    final leaderboard = computeTeamLeaderboard(players, matches);
    final rankIndex = leaderboard.indexWhere((stats) => stats.id == pairId);
    if (rankIndex < 0) return null;
    final together = sortedByMostRecent(matches)
        .where(
          (match) =>
              match.mode == MatchMode.twoVsTwo &&
              (_teamKey(match.team1) == pairId ||
                  _teamKey(match.team2) == pairId),
        )
        .toList(growable: false);
    final opponents = <String, PairOpponentStats>{};
    final results = <bool>[];
    for (final match in together) {
      final side = _teamKey(match.team1) == pairId ? 1 : 2;
      final won = match.winningTeam == side;
      results.add(won);
      final opponentIds = side == 1 ? match.team2 : match.team1;
      final opponentId = _teamKey(opponentIds);
      final previous = opponents[opponentId];
      opponents[opponentId] = PairOpponentStats(
        id: opponentId,
        playerIds: List.unmodifiable([...opponentIds]..sort()),
        games: (previous?.games ?? 0) + 1,
        wins: (previous?.wins ?? 0) + (won ? 1 : 0),
        losses: (previous?.losses ?? 0) + (won ? 0 : 1),
      );
    }
    final rankedOpponents = opponents.values.toList()
      ..sort((first, second) {
        final byGames = second.games.compareTo(first.games);
        return byGames != 0 ? byGames : first.id.compareTo(second.id);
      });
    return PairProfileStats(
      stats: leaderboard[rankIndex],
      rank: rankIndex + 1,
      matches: List.unmodifiable(together),
      recentResults: List.unmodifiable(results.take(5).toList().reversed),
      opponents: List.unmodifiable(rankedOpponents),
    );
  }

  static void _recordTeam({
    required Map<String, _TeamAccumulator> accumulators,
    required List<String> playerIds,
    required bool won,
    required int goals,
  }) {
    final key = _teamKey(playerIds);
    final accumulator = accumulators.putIfAbsent(
      key,
      () => _TeamAccumulator(id: key, playerIds: [...playerIds]..sort()),
    );
    accumulator.games += 1;
    accumulator.wins += won ? 1 : 0;
    accumulator.losses += won ? 0 : 1;
    accumulator.goalsScored += goals;
  }

  static String _teamKey(List<String> playerIds) {
    final sorted = [...playerIds]..sort();
    return jsonEncode(sorted);
  }

  static int _goalsForTeam(GameMatch match, List<String> teamIds) {
    final teamSet = teamIds.toSet();
    return match.scorerIds.where(teamSet.contains).length;
  }
}

class _TeamAccumulator {
  _TeamAccumulator({required this.id, required this.playerIds});

  final String id;
  final List<String> playerIds;
  int games = 0;
  int wins = 0;
  int losses = 0;
  int goalsScored = 0;
  int currentWinStreak = 0;
}
