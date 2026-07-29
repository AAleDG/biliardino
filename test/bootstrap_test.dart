import 'package:biliardino/main.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bootstrap shows a recoverable load failure and retries',
      (tester) async {
    final players = _PlayerRepositoryFake()..loadError = StateError('offline');
    final matches = _MatchRepositoryFake();

    await tester.pumpWidget(BiliardinoBootstrap(
      playerRepository: players,
      matchRepository: matches,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Impossibile caricare i dati.'), findsOneWidget);
    expect(find.byKey(const ValueKey('bootstrap-retry')), findsOneWidget);

    players.loadError = null;
    await tester.tap(find.byKey(const ValueKey('bootstrap-retry')));
    await tester.pump();
    await tester.pump();

    expect(find.byType(BiliardinoApp), findsOneWidget);
    expect(players.loadCalls, 2);
    expect(matches.loadCalls, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(players.disposeCalls, 1);
    expect(matches.disposeCalls, 1);
  });
}

class _PlayerRepositoryFake implements PlayerRepository {
  Object? loadError;
  int loadCalls = 0;
  int disposeCalls = 0;

  @override
  List<Player> get players => const [];

  @override
  Future<void> load() async {
    loadCalls++;
    final error = loadError;
    if (error != null) throw error;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }

  @override
  Future<void> addPlayer(String name) async {}

  @override
  Future<void> togglePresent(Player p) async {}

  @override
  Stream<List<Player>> watchPlayers() => Stream.value(const []);
}

class _MatchRepositoryFake implements MatchRepository {
  Object? loadError;
  int loadCalls = 0;
  int disposeCalls = 0;

  @override
  List<GameMatch> get matches => const [];

  @override
  Future<void> load() async {
    loadCalls++;
    final error = loadError;
    if (error != null) throw error;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }

  @override
  Future<void> addMatch({
    required MatchMode mode,
    required bool isRivalry,
    required List<String> team1,
    required List<String> team2,
    required int score1,
    required int score2,
    required List<String> scorerIds,
  }) async {}

  @override
  Stream<List<GameMatch>> watchMatches() => Stream.value(const []);
}
