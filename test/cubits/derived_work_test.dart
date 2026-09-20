import 'dart:collection';
import 'package:biliardino/cubits/dashboard/dashboard_cubit.dart';
import 'package:biliardino/cubits/history/history_cubit.dart';
import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/cubits/player_profile/player_profile_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/services/stats_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_database.dart';

void main() {
  for (final name in ['dashboard', 'leaderboard', 'history', 'profile']) {
    test(
      '$name does not traverse matches again for identical seeded snapshots',
      () async {
        final db = FakeDatabaseHelper(
          players: [
            Player(
              id: 'p1',
              name: 'One',
              createdAt: DateTime(2026),
              isPresent: true,
            ),
            Player(
              id: 'p2',
              name: 'Two',
              createdAt: DateTime(2026),
              isPresent: true,
            ),
          ],
        );
        final players = PlayerRepository(db);
        await players.load();
        final matches = _CountingList([_match]);
        final repository = _SeededMatches(db, matches);
        final Cubit<dynamic> cubit = switch (name) {
          'dashboard' => DashboardCubit(
            playerRepository: players,
            matchRepository: repository,
          ),
          'leaderboard' => LeaderboardCubit(
            playerRepository: players,
            matchRepository: repository,
          ),
          'history' => HistoryCubit(
            playerRepository: players,
            matchRepository: repository,
          ),
          _ => PlayerProfileCubit(
            playerId: 'p1',
            playerRepository: players,
            matchRepository: repository,
          ),
        };
        final readsAfterConstruction = matches.reads;
        expect(readsAfterConstruction, greaterThan(0));
        await Future<void>.delayed(Duration.zero);
        expect(matches.reads, readsAfterConstruction);
        await cubit.close();
        await players.dispose();
        await repository.dispose();
      },
    );
  }

  test(
    'combined profile/history uses one source traversal with equivalent results',
    () {
      final input = _CountingList([_match]);
      final history = StatsService.playerHistory(input, 'p1');
      final reads = input.reads;
      expect(history.matches.single.id, 'm1');
      expect(history.profile.recentResults, [true]);
      expect(input.reads, reads);
      final selectionOnly = _CountingList([_match]);
      StatsService.matchesForPlayer(selectionOnly, 'p1');
      expect(reads, selectionOnly.reads);
      expect(
        history.profile,
        StatsService.computePlayerProfile([_match], 'p1'),
      );
      expect(() => history.matches.clear(), throwsUnsupportedError);
    },
  );
}

final _match = GameMatch(
  id: 'm1',
  playedAt: DateTime(2026),
  mode: MatchMode.oneVsOne,
  t1p1: 'p1',
  t1p2: '',
  t2p1: 'p2',
  t2p2: '',
  t1Score: 1,
  t2Score: 0,
  winningTeam: 1,
  scorerIds: const ['p1'],
);

class _CountingList extends ListBase<GameMatch> {
  _CountingList(this._values);
  final List<GameMatch> _values;
  int reads = 0;
  @override
  int get length => _values.length;
  @override
  set length(int value) => throw UnsupportedError('immutable');
  @override
  GameMatch operator [](int index) {
    reads++;
    return _values[index];
  }

  @override
  void operator []=(int index, GameMatch value) =>
      throw UnsupportedError('immutable');
}

class _SeededMatches extends MatchRepository {
  _SeededMatches(super.db, this.snapshot);
  final List<GameMatch> snapshot;
  @override
  List<GameMatch> get matches => snapshot;
  @override
  Stream<List<GameMatch>> watchMatches() => Stream.value(snapshot);
}
