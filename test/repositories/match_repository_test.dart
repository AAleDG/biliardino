import 'package:flutter_test/flutter_test.dart';

import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/repositories/match_repository.dart';

import '../support/fake_database.dart';

void main() {
  group('MatchRepository validation', () {
    late FakeDatabaseHelper database;
    late MatchRepository repository;

    setUp(() {
      database = FakeDatabaseHelper();
      repository = MatchRepository(database);
    });

    tearDown(() => repository.dispose());

    test('rejects malformed teams before touching the database', () async {
      await expectLater(
        repository.addMatch(
          mode: MatchMode.twoVsTwo,
          team1: const ['p1'],
          team2: const ['p2', 'p3'],
          score1: 1,
          score2: 0,
          scorerIds: const ['p1'],
        ),
        throwsArgumentError,
      );
      await expectLater(
        repository.addMatch(
          mode: MatchMode.twoVsTwo,
          team1: const ['p1', 'p2'],
          team2: const ['p2', 'p3'],
          score1: 1,
          score2: 0,
          scorerIds: const ['p1'],
        ),
        throwsArgumentError,
      );

      expect(database.insertMatchCalls, 0);
    });

    test('rejects negative and tied scores before touching the database',
        () async {
      await expectLater(
        repository.addMatch(
          mode: MatchMode.twoVsTwo,
          team1: const ['p1', 'p2'],
          team2: const ['p3', 'p4'],
          score1: -1,
          score2: 0,
          scorerIds: const [],
        ),
        throwsArgumentError,
      );
      await expectLater(
        repository.addMatch(
          mode: MatchMode.twoVsTwo,
          team1: const ['p1', 'p2'],
          team2: const ['p3', 'p4'],
          score1: 3,
          score2: 3,
          scorerIds: const [],
        ),
        throwsArgumentError,
      );

      expect(database.insertMatchCalls, 0);
    });
  });

  group('MatchRepository snapshots', () {
    test('stores and emits immutable snapshots', () async {
      final source = [_match('m1')];
      final repository = MatchRepository(FakeDatabaseHelper(matches: source));

      await repository.load();
      final emitted = await repository.watchMatches().first;

      expect(
          () => repository.matches.add(_match('m2')), throwsUnsupportedError);
      expect(() => emitted.clear(), throwsUnsupportedError);

      source.add(_match('m3'));
      expect(repository.matches.map((match) => match.id), ['m1']);

      await repository.dispose();
    });

    test('closes active watchers when disposed', () async {
      final repository = MatchRepository(
        FakeDatabaseHelper(matches: [_match('m1')]),
      );
      await repository.load();

      final events = <List<GameMatch>>[];
      var isDone = false;
      final subscription = repository.watchMatches().listen(
            events.add,
            onDone: () => isDone = true,
          );
      await Future<void>.delayed(Duration.zero);

      await repository.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(isDone, isTrue);
      await subscription.cancel();
    });
  });
}

GameMatch _match(String id) {
  return GameMatch(
    id: id,
    playedAt: DateTime(2026),
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
}
