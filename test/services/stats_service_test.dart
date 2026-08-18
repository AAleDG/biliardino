import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatsService rivalryOverview', () {
    test('isolates rivalry history for the selected pair', () {
      final matches = [
        GameMatch(
          id: 'r1',
          playedAt: DateTime(2026, 7, 1, 12),
          mode: MatchMode.oneVsOne,
          isRivalry: true,
          t1p1: 'p1',
          t1p2: '',
          t2p1: 'p2',
          t2p2: '',
          t1Score: 5,
          t2Score: 3,
          winningTeam: 1,
          scorerIds: const ['p1', 'p1', 'p2', 'p1', 'p2', 'p1', 'p1', 'p2'],
        ),
        GameMatch(
          id: 'r2',
          playedAt: DateTime(2026, 7, 2, 12),
          mode: MatchMode.oneVsOne,
          isRivalry: true,
          t1p1: 'p2',
          t1p2: '',
          t2p1: 'p1',
          t2p2: '',
          t1Score: 5,
          t2Score: 4,
          winningTeam: 1,
          scorerIds: const [
            'p2',
            'p1',
            'p2',
            'p1',
            'p2',
            'p1',
            'p2',
            'p1',
            'p2'
          ],
        ),
        GameMatch(
          id: 'r3',
          playedAt: DateTime(2026, 7, 3, 12),
          mode: MatchMode.oneVsOne,
          t1p1: 'p1',
          t1p2: '',
          t2p1: 'p2',
          t2p2: '',
          t1Score: 2,
          t2Score: 0,
          winningTeam: 1,
          scorerIds: const ['p1', 'p1'],
        ),
      ];

      final overview = StatsService.rivalryOverview(
        matches,
        team1Ids: const ['p1'],
        team2Ids: const ['p2'],
      );

      expect(overview.totalMatches, 2);
      expect(overview.team1Wins, 1);
      expect(overview.team2Wins, 1);
      expect(overview.team1Goals, 9);
      expect(overview.team2Goals, 8);
    });
  });

  group('StatsService computeLeaderboard', () {
    test('assigns badges from ranking, goals, streaks and rivalry wins', () {
      final players = [
        Player(
          id: 'p1',
          name: 'Ale',
          createdAt: DateTime(2026),
          isPresent: true,
        ),
        Player(
          id: 'p2',
          name: 'Luca',
          createdAt: DateTime(2026),
          isPresent: true,
        ),
        Player(
          id: 'p3',
          name: 'Marta',
          createdAt: DateTime(2026),
          isPresent: true,
        ),
      ];
      final matches = [
        GameMatch(
          id: 'm3',
          playedAt: DateTime(2026, 7, 3),
          mode: MatchMode.oneVsOne,
          isRivalry: true,
          t1p1: 'p1',
          t1p2: '',
          t2p1: 'p2',
          t2p2: '',
          t1Score: 5,
          t2Score: 1,
          winningTeam: 1,
          scorerIds: const ['p1', 'p1', 'p2', 'p1', 'p1', 'p1'],
        ),
        GameMatch(
          id: 'm2',
          playedAt: DateTime(2026, 7, 2),
          mode: MatchMode.oneVsOne,
          isRivalry: true,
          t1p1: 'p1',
          t1p2: '',
          t2p1: 'p2',
          t2p2: '',
          t1Score: 5,
          t2Score: 2,
          winningTeam: 1,
          scorerIds: const ['p1', 'p1', 'p2', 'p1', 'p2', 'p1', 'p1'],
        ),
        GameMatch(
          id: 'm1',
          playedAt: DateTime(2026, 7, 1),
          mode: MatchMode.oneVsOne,
          t1p1: 'p1',
          t1p2: '',
          t2p1: 'p3',
          t2p2: '',
          t1Score: 4,
          t2Score: 1,
          winningTeam: 1,
          scorerIds: const ['p1', 'p3', 'p1', 'p1', 'p1'],
        ),
      ];

      final stats = StatsService.computeLeaderboard(players, matches);
      final ale = stats.firstWhere((entry) => entry.player.id == 'p1');

      expect(ale.currentWinStreak, 3);
      expect(
        ale.badges.map((badge) => badge.code),
        containsAll(<String>['leader', 'bomber', 'streak', 'rivalry']),
      );
    });
  });
}
