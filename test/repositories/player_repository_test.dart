import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_database.dart';

void main() {
  group('PlayerRepository', () {
    test('stores and emits immutable snapshots', () async {
      final source = [_player('p1')];
      final database = FakeDatabaseHelper(players: source);
      final repository = PlayerRepository(database);

      await repository.load();
      final emitted = await repository.watchPlayers().first;

      expect(
        () => repository.players.add(_player('p2')),
        throwsUnsupportedError,
      );
      expect(() => emitted.clear(), throwsUnsupportedError);

      source.add(_player('p3'));
      expect(repository.players.map((player) => player.id), ['p1']);

      await repository.dispose();
    });

    test('closes active watchers when disposed', () async {
      final repository = PlayerRepository(
        FakeDatabaseHelper(players: [_player('p1')]),
      );
      await repository.load();

      final events = <List<Player>>[];
      var isDone = false;
      final subscription = repository.watchPlayers().listen(
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

    test(
      'rejects empty and duplicate names before touching the database',
      () async {
        final database = FakeDatabaseHelper(players: [_player('p1')]);
        final repository = PlayerRepository(database);
        await repository.load();

        await expectLater(repository.addPlayer(' '), throwsArgumentError);
        await expectLater(repository.addPlayer('P1'), throwsArgumentError);
        await expectLater(
          repository.renamePlayer(_player('p2'), 'p1'),
          throwsArgumentError,
        );

        expect(database.insertPlayerCalls, 0);
        expect(database.updatePlayerCalls, 0);
        await repository.dispose();
      },
    );

    test(
      'rejects duplicate names from the database before inserting',
      () async {
        final database = FakeDatabaseHelper()..hasDuplicatePlayerName = true;
        final repository = PlayerRepository(database);

        await expectLater(repository.addPlayer(' Mario '), throwsArgumentError);

        expect(database.insertPlayerCalls, 0);
        await repository.dispose();
      },
    );

    test(
      'rejects duplicate names with unicode whitespace from the cache',
      () async {
        final database = FakeDatabaseHelper(
          players: [_playerWithName(id: 'p1', name: 'Ada Lovelace')],
        );
        final repository = PlayerRepository(database);
        await repository.load();

        await expectLater(
          repository.addPlayer(' ADA\u00A0LOVELACE '),
          throwsArgumentError,
        );
        await expectLater(
          repository.renamePlayer(_player('p2'), 'Ada\u2007Lovelace'),
          throwsArgumentError,
        );

        expect(database.insertPlayerCalls, 0);
        expect(database.updatePlayerCalls, 0);
        await repository.dispose();
      },
    );

    test('archives and reactivates players without removing them', () async {
      final player = _player('p1');
      final database = FakeDatabaseHelper(players: [player]);
      final repository = PlayerRepository(database);
      await repository.load();

      await repository.archivePlayer(player);

      expect(repository.players.single.isArchived, isTrue);
      expect(repository.players.single.isPresent, isFalse);

      await repository.reactivatePlayer(repository.players.single);

      expect(repository.players.single.isArchived, isFalse);
      expect(repository.players.single.isPresent, isFalse);
      expect(database.updatePlayerCalls, 2);
      await repository.dispose();
    });

    test('rejects presence changes for archived players', () async {
      final archived = Player(
        id: 'p1',
        name: 'Mario',
        createdAt: DateTime(2026),
        isPresent: false,
        isArchived: true,
      );
      final database = FakeDatabaseHelper(players: [archived]);
      final repository = PlayerRepository(database);
      await repository.load();

      await expectLater(repository.togglePresent(archived), throwsStateError);

      expect(database.updatePlayerCalls, 0);
      await repository.dispose();
    });
  });
}

Player _player(String id) {
  return Player(id: id, name: id, createdAt: DateTime(2026), isPresent: true);
}

Player _playerWithName({required String id, required String name}) {
  return Player(id: id, name: name, createdAt: DateTime(2026), isPresent: true);
}
