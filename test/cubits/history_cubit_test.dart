import 'package:biliardino/cubits/history/history_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_database.dart';

void main() {
  test('editing and deleting refresh history immediately', () async {
    final database = FakeDatabaseHelper(
      players: _players,
      matches: [_match],
    );
    final playerRepository = PlayerRepository(database);
    final matchRepository = MatchRepository(database);
    await playerRepository.load();
    await matchRepository.load();
    final cubit = HistoryCubit(
      playerRepository: playerRepository,
      matchRepository: matchRepository,
    );
    await Future<void>.delayed(Duration.zero);

    final corrected = _match.copyWith(
      playedAt: DateTime(2026, 8, 27, 13, 30),
      t1Score: 2,
      scorerIds: const ['p1', 'p2'],
    );
    await cubit.updateMatch(corrected);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.filteredMatches.single.playedAt, corrected.playedAt);
    expect(cubit.state.filteredMatches.single.t1Score, 2);

    await cubit.deleteMatch(corrected);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.filteredMatches, isEmpty);
    expect(cubit.state.matchesCount, 0);

    await cubit.close();
    await playerRepository.dispose();
    await matchRepository.dispose();
  });
}

final _players = [
  Player(
    id: 'p1',
    name: 'Ada',
    createdAt: DateTime(2026),
    isPresent: true,
  ),
  Player(
    id: 'p2',
    name: 'Bea',
    createdAt: DateTime(2026),
    isPresent: true,
  ),
  Player(
    id: 'p3',
    name: 'Carlo',
    createdAt: DateTime(2026),
    isPresent: true,
  ),
  Player(
    id: 'p4',
    name: 'Dario',
    createdAt: DateTime(2026),
    isPresent: true,
  ),
];

final _match = GameMatch(
  id: 'm1',
  playedAt: DateTime(2026, 8, 27, 12),
  mode: MatchMode.twoVsTwo,
  t1p1: 'p1',
  t1p2: 'p2',
  t2p1: 'p3',
  t2p2: 'p4',
  t1Score: 1,
  t2Score: 0,
  winningTeam: 1,
  scorerIds: const ['p1'],
);
