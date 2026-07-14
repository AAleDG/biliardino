import 'package:flutter_test/flutter_test.dart';

import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/player_repository.dart';

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
          () => repository.players.add(_player('p2')), throwsUnsupportedError);
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
  });
}

Player _player(String id) {
  return Player(id: id, name: id, createdAt: DateTime(2026));
}
