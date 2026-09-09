import 'package:biliardino/cubits/dashboard/dashboard_cubit.dart';
import 'package:biliardino/cubits/history/history_cubit.dart';
import 'package:biliardino/cubits/history/history_filters.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_database.dart';

void main() {
  group('DashboardCubit', () {
    test('derives empty state without fixture content', () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);

      expect(harness.cubit.state.isLoading, isFalse);
      expect(harness.cubit.state.recentMatches, isEmpty);
      expect(harness.cubit.state.ranking, isEmpty);
    });

    test(
      'keeps five newest unfiltered matches and formats both team sizes',
      () async {
        final matches = [
          _match('m3', DateTime(2026, 9, 3), ['p1'], ['missing'], 3, 1),
          _match('m1', DateTime(2026, 9, 1), ['p1'], ['p2'], 1, 0),
          _match('m6', DateTime(2026, 9, 6), ['p1', 'p2'], ['p3', 'p4'], 2, 1),
          _match('m2', DateTime(2026, 9, 2), ['p2'], ['p3'], 0, 2),
          _match('m5', DateTime(2026, 9, 5), ['p4'], ['p1'], 0, 1),
          _match('m4', DateTime(2026, 9, 4), ['p3'], ['p4'], 1, 0),
        ];
        final harness = await _Harness.create(
          players: _players,
          matches: matches,
        );
        addTearDown(harness.dispose);

        expect(
          harness.cubit.state.recentMatches.map((summary) => summary.match.id),
          ['m6', 'm5', 'm4', 'm3', 'm2'],
        );
        final doubles = harness.cubit.state.recentMatches.first;
        expect(doubles.teamOneName, 'Ale · Bea');
        expect(doubles.teamTwoName, 'Carlo · Daria');
        final missing = harness.cubit.state.recentMatches.singleWhere(
          (summary) => summary.match.id == 'm3',
        );
        expect(missing.teamOneName, 'Ale');
        expect(missing.teamTwoName, '—');
      },
    );

    test('does not inherit mutable History filters', () async {
      final matches = [
        _match('one', DateTime(2026, 9, 1), ['p1'], ['p2'], 1, 0),
        _match('two', DateTime(2026, 9, 2), ['p1', 'p2'], ['p3', 'p4'], 2, 1),
      ];
      final harness = await _Harness.create(
        players: _players,
        matches: matches,
      );
      addTearDown(harness.dispose);
      final history = HistoryCubit(
        playerRepository: harness.playerRepository,
        matchRepository: harness.matchRepository,
      );
      addTearDown(history.close);
      history.applyFilters(
        const HistoryFilters(matchMode: HistoryMatchModeFilter.oneVsOne),
      );
      await _flush();

      expect(history.state.filteredMatches.map((match) => match.id), ['one']);
      expect(
        harness.cubit.state.recentMatches.map((summary) => summary.match.id),
        ['two', 'one'],
      );
    });

    test(
      'uses existing ranking points and tie ordering for played players only',
      () async {
        final archived = _players[3].copyWith(
          isArchived: true,
          isPresent: false,
        );
        final players = [..._players.take(3), archived, _unplayed];
        final matches = [
          _match('new', DateTime(2026, 9, 2), ['p4'], ['p3'], 1, 0),
          _match('old', DateTime(2026, 9, 1), ['p1', 'p2'], ['p3', 'p4'], 2, 0),
        ];
        final harness = await _Harness.create(
          players: players,
          matches: matches,
        );
        addTearDown(harness.dispose);

        expect(harness.cubit.state.ranking, hasLength(4));
        expect(harness.cubit.state.ranking.map((stats) => stats.player.id), [
          'p1',
          'p2',
          'p4',
          'p3',
        ]);
        expect(harness.cubit.state.ranking.map((stats) => stats.points), [
          3,
          3,
          3,
          0,
        ]);
        expect(harness.cubit.state.ranking[2].player.isArchived, isTrue);
        expect(
          harness.cubit.state.ranking.any((stats) => stats.player.id == 'p5'),
          isFalse,
        );
      },
    );

    test(
      'reacts to repository save, edit, delete and restore publications',
      () async {
        final initial = _match(
          'initial',
          DateTime(2026, 9, 1),
          ['p1'],
          ['p2'],
          1,
          0,
        );
        final harness = await _Harness.create(
          players: _players,
          matches: [initial],
        );
        addTearDown(harness.dispose);

        await harness.matchRepository.addMatch(
          mode: MatchMode.oneVsOne,
          isRivalry: false,
          team1: const ['p2'],
          team2: const ['p3'],
          score1: 0,
          score2: 1,
          scorerIds: const ['p3'],
        );
        await _flush();
        expect(harness.cubit.state.recentMatches, hasLength(2));

        final saved = harness.matchRepository.matches.first;
        await harness.matchRepository.updateMatch(
          saved.copyWith(
            t1Score: 2,
            t2Score: 0,
            winningTeam: 1,
            scorerIds: const ['p2', 'p2'],
          ),
        );
        await _flush();
        expect(harness.cubit.state.recentMatches.first.match.t1Score, 2);

        await harness.matchRepository.deleteMatch(saved.id);
        await _flush();
        expect(harness.cubit.state.recentMatches.single.match.id, 'initial');

        harness.database.matches
          ..clear()
          ..add(_match('restored', DateTime(2026, 9, 8), ['p3'], ['p4'], 0, 1));
        await harness.matchRepository.load();
        await _flush();
        expect(harness.cubit.state.recentMatches.single.match.id, 'restored');
      },
    );
  });
}

class _Harness {
  _Harness({
    required this.database,
    required this.playerRepository,
    required this.matchRepository,
    required this.cubit,
  });

  final FakeDatabaseHelper database;
  final PlayerRepository playerRepository;
  final MatchRepository matchRepository;
  final DashboardCubit cubit;

  static Future<_Harness> create({
    List<Player> players = const [],
    List<GameMatch> matches = const [],
  }) async {
    final database = FakeDatabaseHelper(players: players, matches: matches);
    final playerRepository = PlayerRepository(database);
    final matchRepository = MatchRepository(database);
    await playerRepository.load();
    await matchRepository.load();
    final cubit = DashboardCubit(
      playerRepository: playerRepository,
      matchRepository: matchRepository,
    );
    await _flush();
    return _Harness(
      database: database,
      playerRepository: playerRepository,
      matchRepository: matchRepository,
      cubit: cubit,
    );
  }

  Future<void> dispose() async {
    await cubit.close();
    await playerRepository.dispose();
    await matchRepository.dispose();
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

GameMatch _match(
  String id,
  DateTime playedAt,
  List<String> teamOne,
  List<String> teamTwo,
  int scoreOne,
  int scoreTwo,
) {
  return GameMatch(
    id: id,
    playedAt: playedAt,
    mode: teamOne.length == 1 ? MatchMode.oneVsOne : MatchMode.twoVsTwo,
    t1p1: teamOne.first,
    t1p2: teamOne.length == 2 ? teamOne.last : '',
    t2p1: teamTwo.first,
    t2p2: teamTwo.length == 2 ? teamTwo.last : '',
    t1Score: scoreOne,
    t2Score: scoreTwo,
    winningTeam: scoreOne > scoreTwo ? 1 : 2,
    scorerIds: [
      ...List.filled(scoreOne, teamOne.first),
      ...List.filled(scoreTwo, teamTwo.first),
    ],
  );
}

final _players = [
  Player(id: 'p1', name: 'Ale', createdAt: DateTime(2026), isPresent: true),
  Player(id: 'p2', name: 'Bea', createdAt: DateTime(2026), isPresent: true),
  Player(id: 'p3', name: 'Carlo', createdAt: DateTime(2026), isPresent: true),
  Player(id: 'p4', name: 'Daria', createdAt: DateTime(2026), isPresent: true),
];

final _unplayed = Player(
  id: 'p5',
  name: 'Elio',
  createdAt: DateTime(2026),
  isPresent: true,
);
