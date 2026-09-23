import 'support/fake_database.dart';
import 'package:biliardino/repositories/app_style_repository.dart';
import 'support/fake_data_management.dart';
import 'package:biliardino/main.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/match_rules.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/match_rules_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bootstrap shows a recoverable load failure and retries', (
    tester,
  ) async {
    final players = _PlayerRepositoryFake()..loadError = StateError('offline');
    final data = FakeData();
    final matches = _MatchRepositoryFake();
    final rules = _MatchRulesRepositoryFake();

    await tester.pumpWidget(
      BiliardinoBootstrap(
        playerRepository: players,
        matchRepository: matches,
        matchRulesRepository: rules,
        dataManagementRepository: data,
        appStyleRepository: AppStyleRepository(FakeDatabaseHelper()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Impossibile caricare i dati.'), findsOneWidget);
    expect(find.byKey(const ValueKey('bootstrap-retry')), findsOneWidget);

    players.loadError = null;
    await tester.tap(find.byKey(const ValueKey('bootstrap-retry')));
    await tester.pump();
    await tester.pump();

    expect(find.byType(BiliardinoApp), findsOneWidget);
    expect(
      tester
          .widget<BiliardinoApp>(find.byType(BiliardinoApp))
          .dataManagementRepository,
      same(data),
    );
    expect(players.loadCalls, 2);
    expect(matches.loadCalls, 2);
    expect(rules.loadCalls, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(players.disposeCalls, 1);
    expect(matches.disposeCalls, 1);
  });
  testWidgets(
    'style load failure uses the existing retry and preserves injected owners',
    (tester) async {
      final db = _StyleDatabase();
      final style = AppStyleRepository(db);
      final players = _PlayerRepositoryFake();
      await tester.pumpWidget(
        BiliardinoBootstrap(
          playerRepository: players,
          matchRepository: _MatchRepositoryFake(),
          matchRulesRepository: _MatchRulesRepositoryFake(),
          dataManagementRepository: FakeData(),
          appStyleRepository: style,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bootstrap-retry')), findsOneWidget);
      db.fail = false;
      await tester.tap(find.byKey(const ValueKey('bootstrap-retry')));
      await tester.pump();
      await tester.pump();
      final app = tester.widget<BiliardinoApp>(find.byType(BiliardinoApp));
      expect(app.appStyleRepository, same(style));
      expect(app.playerRepository, same(players));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
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
  Future<void> renamePlayer(Player player, String name) async {}

  @override
  Future<void> archivePlayer(Player player) async {}

  @override
  Future<void> reactivatePlayer(Player player) async {}

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
  Future<void> updateMatch(GameMatch match) async {}

  @override
  Future<void> deleteMatch(String id) async {}

  @override
  Stream<List<GameMatch>> watchMatches() => Stream.value(const []);
}

class _MatchRulesRepositoryFake implements MatchRulesRepository {
  int loadCalls = 0;

  @override
  MatchRules get rules => MatchRules.defaultRules;

  @override
  Future<void> load() async {
    loadCalls++;
  }

  @override
  Future<void> save(MatchRules rules) async {}
}

class _StyleDatabase extends FakeDatabaseHelper {
  bool fail = true;
  @override
  Future<Map<String, String>> getSettings(List<String> keys) {
    if (fail) throw StateError('style storage unavailable');
    return super.getSettings(keys);
  }
}
