import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:biliardino/cubits/players/players_cubit.dart';
import 'package:biliardino/cubits/players/players_state.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/player_repository.dart';

void main() {
  group('PlayersCubit', () {
    test('surfaces a mutation failure and allows retry', () async {
      final repository = _PlayerRepositoryFake();
      final cubit = PlayersCubit(repository);
      await Future<void>.delayed(Duration.zero);

      repository.addError = StateError('database down');
      expect(await cubit.addPlayer('Mario'), isFalse);
      expect(cubit.state.isMutating, isFalse);
      expect(cubit.state.feedback, PlayersFeedback.addFailed);

      repository.addError = null;
      expect(await cubit.addPlayer('Mario'), isTrue);
      expect(cubit.state.isMutating, isFalse);
      expect(repository.addCalls, 2);

      await cubit.close();
      await repository.dispose();
    });

    test('rejects overlapping mutations', () async {
      final repository = _PlayerRepositoryFake();
      final pending = Completer<void>();
      repository.pendingAdd = pending;
      final cubit = PlayersCubit(repository);
      await Future<void>.delayed(Duration.zero);

      final first = cubit.addPlayer('Mario');
      final second = cubit.addPlayer('Luigi');

      expect(await second, isFalse);
      expect(repository.addCalls, 1);
      pending.complete();
      expect(await first, isTrue);

      await cubit.close();
      await repository.dispose();
    });
  });
}

class _PlayerRepositoryFake implements PlayerRepository {
  final StreamController<List<Player>> _controller =
      StreamController<List<Player>>.broadcast();
  Object? addError;
  Completer<void>? pendingAdd;
  int addCalls = 0;

  @override
  List<Player> get players => const [];

  @override
  Future<void> addPlayer(String name) async {
    addCalls++;
    final error = addError;
    if (error != null) throw error;
    await pendingAdd?.future;
  }

  @override
  Future<void> renamePlayer(Player player, String name) async {}

  @override
  Future<void> dispose() => _controller.close();

  @override
  Future<void> load() async {}

  @override
  Future<void> togglePresent(Player p) async {}

  @override
  Stream<List<Player>> watchPlayers() async* {
    yield const [];
    yield* _controller.stream;
  }
}
