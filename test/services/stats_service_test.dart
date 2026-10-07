import 'dart:convert';
import 'package:biliardino/services/data_backup_service.dart';
import '../support/fake_database.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('recurring pair rankings', () {
    final players = [
      for (final (id, name) in [
        ('a', 'Anna'),
        ('b', 'Bruno'),
        ('c', 'Carla'),
        ('d', 'Dario'),
        ('e', 'Elena'),
        ('f', 'Fabio'),
      ])
        Player(id: id, name: name, isPresent: true, createdAt: DateTime(2026)),
    ];
    test(
      'membership ignores side/order; distinct partnerships and legacy goals stay separate',
      () {
        final matches = [
          _match('old', DateTime(2026, 1, 1), ['a', 'b'], ['c', 'd'], 1),
          _match('new', DateTime(2026, 1, 3), ['d', 'c'], ['b', 'a'], 2),
          _match('other', DateTime(2026, 1, 2), ['a', 'e'], ['c', 'd'], 2),
          GameMatch(
            id: 'single',
            playedAt: DateTime(2026, 1, 4),
            mode: MatchMode.oneVsOne,
            t1p1: 'a',
            t1p2: '',
            t2p1: 'f',
            t2p2: '',
            t1Score: 5,
            t2Score: 0,
            winningTeam: 1,
            scorerIds: const ['a', 'a', 'a', 'a', 'a'],
          ),
        ];
        final ranked = StatsService.computeTeamLeaderboard(players, matches);
        expect(ranked.map((s) => s.name), [
          'Anna + Bruno',
          'Carla + Dario',
          'Anna + Elena',
        ]);
        expect(ranked.first.games, 2);
        expect(ranked.first.points, 6);
        expect(ranked.first.currentWinStreak, 2);
        expect(ranked.first.goalsScored, 0);
        final profile = StatsService.computePairProfile(
          players,
          matches,
          ranked.first.id,
        )!;
        expect(profile.matches.map((m) => m.id), ['new', 'old']);
        expect(profile.recentResults, [true, true]);
        expect(profile.opponents.single.games, 2);
        expect(() => ranked.first.players.clear(), throwsUnsupportedError);
        expect(() => profile.matches.clear(), throwsUnsupportedError);
      },
    );
    test('valid imported opaque IDs cannot collapse two distinct pairs', () {
      final roster = [
        for (final (id, name) in [
          ('a', 'Anna'),
          ('b|c', 'Bruno'),
          ('a|b', 'Carla'),
          ('c', 'Dario'),
          ('d', 'Elena'),
          ('e', 'Fabio'),
        ])
          Player(
            id: id,
            name: name,
            isPresent: true,
            createdAt: DateTime(2026),
          ),
      ];
      final matches = [
        _match('one', DateTime(2026, 1, 1), ['a', 'b|c'], ['d', 'e'], 1),
        _match('two', DateTime(2026, 1, 2), ['a|b', 'c'], ['d', 'e'], 2),
      ];
      final backup = DataBackupService(FakeDatabaseHelper()).parse(
        jsonEncode({
          'version': 0,
          'players': roster.map((p) => p.toMap()).toList(),
          'matches': matches.map((m) => m.toMap()).toList(),
        }),
      );
      final ranked = StatsService.computeTeamLeaderboard(
        backup.players,
        backup.matches,
      );
      expect(ranked.map((s) => s.name), [
        'Anna + Bruno',
        'Elena + Fabio',
        'Carla + Dario',
      ]);
      expect(ranked.map((s) => s.id).toSet(), hasLength(3));
      expect(ranked.last.losses, 1);
      expect(
        StatsService.computePairProfile(
          backup.players,
          backup.matches,
          ranked.last.id,
        )!.matches.single.id,
        'two',
      );
    });
    test(
      'attributed pair goals and alphabetical ties exclude legacy score totals',
      () {
        final match = GameMatch(
          id: 'goals',
          playedAt: DateTime(2026),
          mode: MatchMode.twoVsTwo,
          t1p1: 'a',
          t1p2: 'b',
          t2p1: 'c',
          t2p2: 'd',
          t1Score: 3,
          t2Score: 1,
          winningTeam: 1,
          scorerIds: ['a', 'b', 'a', 'd'],
        );
        final ranked = StatsService.computeTeamLeaderboard(players, [match]);
        expect(ranked.map((s) => s.goalsScored), [3, 1]);
        final profile = StatsService.computePairProfile(players, [
          match,
        ], ranked.first.id)!;
        match.scorerIds.clear();
        expect(profile.matches.single.scorerIds, ['a', 'b', 'a', 'd']);
        expect(
          () => profile.matches.single.scorerIds.clear(),
          throwsUnsupportedError,
        );
        expect(
          ranked.first.badges.map((b) => b.code),
          containsAll(['leader', 'bomber']),
        );
        final tied = StatsService.computeTeamLeaderboard(players, [
          match,
          _match('tie', DateTime(2026, 1, 2), ['c', 'd'], ['a', 'b'], 1),
        ]);
        expect(tied.map((s) => s.name), ['Anna + Bruno', 'Carla + Dario']);
      },
    );
  });
  group('StatsService computePlayerProfile', () {
    test('computes recent form, relationships and head-to-head', () {
      final matches = [
        _match('new', DateTime(2026, 7, 3), ['p1', 'p2'], ['p3', 'p4'], 1),
        _match('mid', DateTime(2026, 7, 2), ['p3', 'p1'], ['p2', 'p4'], 1),
        _match('old', DateTime(2026, 7, 1), ['p1', 'p2'], ['p3', 'p4'], 2),
      ];

      final profile = StatsService.computePlayerProfile(matches, 'p1');

      expect(profile.recentResults, [true, true, false]);
      expect(profile.mostFrequentTeammate?.playerIds, ['p2']);
      expect(profile.mostFrequentTeammate?.matches, 2);
      expect(profile.mostPlayedOpponent?.playerIds, ['p4']);
      expect(profile.mostPlayedOpponent?.matches, 3);
      final againstP3 = profile.headToHead.firstWhere(
        (item) => item.opponentId == 'p3',
      );
      expect(againstP3.games, 2);
      expect(againstP3.wins, 1);
      expect(againstP3.losses, 1);
    });

    test('handles a player with no matches', () {
      final profile = StatsService.computePlayerProfile(const [], 'p1');

      expect(profile.recentResults, isEmpty);
      expect(profile.mostFrequentTeammate, isNull);
      expect(profile.mostPlayedOpponent, isNull);
      expect(profile.headToHead, isEmpty);
    });

    test('breaks relationship frequency ties by most recent match', () {
      final matches = [
        _match(
          'older',
          DateTime(2026, 7, 1),
          ['p1', 'a-older-teammate'],
          ['a-older-opponent', 'b-older-opponent'],
          1,
        ),
        _match(
          'newer',
          DateTime(2026, 7, 2),
          ['p1', 'z-newer-teammate'],
          ['y-newer-opponent', 'z-newer-opponent'],
          1,
        ),
      ];

      final profile = StatsService.computePlayerProfile(matches, 'p1');

      expect(profile.mostFrequentTeammate?.playerIds, ['z-newer-teammate']);
      expect(profile.mostPlayedOpponent?.playerIds, {
        'y-newer-opponent',
        'z-newer-opponent',
      });
    });

    test('keeps every exact tie regardless of player ID ordering', () {
      final firstProfile = StatsService.computePlayerProfile([
        _match(
          'first',
          DateTime(2026, 7, 2),
          ['p1', 'teammate'],
          ['z-opponent', 'a-opponent'],
          1,
        ),
      ], 'p1');
      final reversedProfile = StatsService.computePlayerProfile([
        _match(
          'reversed',
          DateTime(2026, 7, 2),
          ['p1', 'teammate'],
          ['a-opponent', 'z-opponent'],
          1,
        ),
      ], 'p1');

      expect(firstProfile.mostPlayedOpponent?.playerIds, {
        'a-opponent',
        'z-opponent',
      });
      expect(reversedProfile.mostPlayedOpponent?.playerIds, {
        'a-opponent',
        'z-opponent',
      });
    });
  });

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
            'p2',
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
    test('orders by points, then win rate, then case-insensitive name', () {
      final players = [
        for (final name in ['Zeta', 'Bea', 'anna', 'Carlo', 'Opponent', 'Idle'])
          Player(
            id: name,
            name: name,
            createdAt: DateTime(2026),
            isPresent: true,
          ),
      ];
      final matches = <GameMatch>[];
      void result(String player, bool won) {
        matches.add(
          GameMatch(
            id: 'm${matches.length}',
            playedAt: DateTime(2026, 1, matches.length + 1),
            mode: MatchMode.oneVsOne,
            t1p1: player,
            t1p2: '',
            t2p1: 'Opponent',
            t2p2: '',
            t1Score: won ? 2 : 0,
            t2Score: won ? 0 : 2,
            winningTeam: won ? 1 : 2,
            scorerIds: const [],
          ),
        );
      }

      for (final won in [true, true, false, false]) {
        result('Zeta', won);
      }
      result('Bea', true);
      result('anna', true);
      result('Carlo', true);
      result('Carlo', false);
      final ranked = StatsService.computeLeaderboard(players, matches);
      expect(ranked.map((s) => s.player.name), [
        'Opponent',
        'Zeta',
        'anna',
        'Bea',
        'Carlo',
        'Idle',
      ]);
      expect(ranked.map((s) => s.points), [9, 6, 3, 3, 3, 0]);
      expect(ranked.map((s) => s.games), [8, 4, 1, 1, 2, 0]);
      expect(ranked.map((s) => s.winRate), [3 / 8, .5, 1, 1, .5, 0]);
    });

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

GameMatch _match(
  String id,
  DateTime playedAt,
  List<String> team1,
  List<String> team2,
  int winningTeam,
) {
  return GameMatch(
    id: id,
    playedAt: playedAt,
    mode: MatchMode.twoVsTwo,
    t1p1: team1[0],
    t1p2: team1[1],
    t2p1: team2[0],
    t2p2: team2[1],
    t1Score: winningTeam == 1 ? 2 : 1,
    t2Score: winningTeam == 2 ? 2 : 1,
    winningTeam: winningTeam,
    scorerIds: const [],
  );
}
