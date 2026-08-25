import 'dart:convert';

import 'package:biliardino/data/database_helper.dart';
import 'package:biliardino/models/player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  });

  tearDown(() async {
    await database.close();
  });

  test('migrates v3 players to v5 without changing match identities', () async {
    await _createPlayersTable(database, withNameKey: false);
    await _createMatchesTable(database);
    await _insertPlayer(
      database,
      id: 'marco-old',
      name: 'Marco',
      createdAt: 1,
      withNameKey: false,
    );
    await _insertPlayer(
      database,
      id: 'marco-new',
      name: 'marco',
      createdAt: 2,
      withNameKey: false,
    );
    await _insertPlayer(
      database,
      id: 'existing-suffix',
      name: 'Marco (2)',
      createdAt: 3,
      withNameKey: false,
    );
    await _insertMatch(
      database,
      id: 'm1',
      t1p1: 'marco-old',
      t1p2: 'existing-suffix',
      t2p1: 'marco-new',
      t2p2: 'p4',
      scorerIds: const ['marco-old', 'marco-new', 'marco-new'],
    );
    await _insertMatch(
      database,
      id: 'm2',
      t1p1: 'marco-new',
      t1p2: 'existing-suffix',
      t2p1: 'p3',
      t2p2: 'marco-old',
      scorerIds: const ['marco-new', 'marco-old'],
    );

    await DatabaseHelper.migratePlayersToUniqueNames(database);
    await DatabaseHelper.migratePlayersToPersistedUniqueNameKeys(database);

    final players = await database.query('players', orderBy: 'id');
    final matches = await database.query('matches', orderBy: 'id');

    expect(players.map((row) => row['id']), [
      'existing-suffix',
      'marco-new',
      'marco-old',
    ]);
    expect(players.map((row) => row['name']), [
      'Marco (2)',
      'Marco (3)',
      'Marco',
    ]);
    expect(players.map((row) => row['name_key']), [
      'marco (2)',
      'marco (3)',
      'marco',
    ]);
    expect(matches[0]['t1p1'], 'marco-old');
    expect(matches[0]['t2p1'], 'marco-new');
    expect(
      matches[0]['scorer_ids_json'],
      '["marco-old","marco-new","marco-new"]',
    );
    expect(matches[1]['t1p1'], 'marco-new');
    expect(matches[1]['t2p2'], 'marco-old');
    expect(matches[1]['scorer_ids_json'], '["marco-new","marco-old"]');
    await expectLater(
      database.insert(
        'players',
        _playerRow(id: 'new', name: ' MARCO ', createdAt: 4, withNameKey: true),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test(
    'migrates already altered v4 databases to v5 non-destructively',
    () async {
      await _createPlayersTable(database, withNameKey: false);
      await _createMatchesTable(database);
      await _insertPlayer(
        database,
        id: 'busy',
        name: 'Mario',
        createdAt: 1,
        withNameKey: false,
      );
      await _insertPlayer(
        database,
        id: 'other',
        name: 'Luigi',
        createdAt: 2,
        withNameKey: false,
      );
      await _insertMatch(
        database,
        id: 'm1',
        t1p1: 'busy',
        t1p2: 'other',
        t2p1: 'p3',
        t2p2: 'p4',
        scorerIds: const ['busy', 'busy', 'busy', 'busy'],
      );
      await _createLegacyPlayersNameIndex(database);

      await DatabaseHelper.migratePlayersToPersistedUniqueNameKeys(database);

      final players = await database.query('players', orderBy: 'id');
      final matches = await database.query('matches', orderBy: 'id');
      final indexes = await database.rawQuery('PRAGMA index_list(players)');

      expect(players.map((row) => row['id']), ['busy', 'other']);
      expect(players.map((row) => row['name']), ['Mario', 'Luigi']);
      expect(players.map((row) => row['name_key']), ['mario', 'luigi']);
      expect(matches.single['t1p1'], 'busy');
      expect(
        matches.single['scorer_ids_json'],
        '["busy","busy","busy","busy"]',
      );
      expect(
        indexes.map((row) => row['name']),
        isNot(contains('idx_players_name_nocase')),
      );
      expect(
        indexes.map((row) => row['name']),
        contains('idx_players_name_key'),
      );
    },
  );

  test(
    'uses the persisted Dart normalization for unicode whitespace',
    () async {
      await _createPlayersTable(database, withNameKey: false);
      await _createMatchesTable(database);
      await _insertPlayer(
        database,
        id: 'ada-old',
        name: 'Ada Lovelace',
        createdAt: 1,
        withNameKey: false,
      );
      await _insertPlayer(
        database,
        id: 'ada-new',
        name: 'ada\u00A0lovelace',
        createdAt: 2,
        withNameKey: false,
      );

      await DatabaseHelper.migratePlayersToPersistedUniqueNameKeys(database);

      final players = await database.query('players', orderBy: 'created_at');

      expect(players.map((row) => row['name']), [
        'Ada Lovelace',
        'Ada Lovelace (2)',
      ]);
      expect(players.map((row) => row['name_key']), [
        'ada lovelace',
        'ada lovelace (2)',
      ]);
      await expectLater(
        database.insert(
          'players',
          _playerRow(
            id: 'ada-third',
            name: ' ADA\u2007LOVELACE ',
            createdAt: 3,
            withNameKey: true,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test('v5 migration is idempotent and resolves suffix collisions', () async {
    await _createPlayersTable(database, withNameKey: false);
    await _createMatchesTable(database);
    await _insertPlayer(
      database,
      id: 'ada-old',
      name: 'Ada Lovelace',
      createdAt: 1,
      withNameKey: false,
    );
    await _insertPlayer(
      database,
      id: 'ada-new',
      name: 'ada\u202Flovelace',
      createdAt: 2,
      withNameKey: false,
    );
    await _insertPlayer(
      database,
      id: 'ada-suffix',
      name: 'Ada Lovelace (2)',
      createdAt: 3,
      withNameKey: false,
    );

    await DatabaseHelper.migratePlayersToPersistedUniqueNameKeys(database);
    await DatabaseHelper.migratePlayersToPersistedUniqueNameKeys(database);

    final players = await database.query('players', orderBy: 'id');
    final indexes = await database.rawQuery('PRAGMA index_list(players)');

    expect(players.map((row) => row['name']), [
      'Ada Lovelace (3)',
      'Ada Lovelace',
      'Ada Lovelace (2)',
    ]);
    expect(players.map((row) => row['name_key']), [
      'ada lovelace (3)',
      'ada lovelace',
      'ada lovelace (2)',
    ]);
    expect(players.every((row) => row['name_key'] != null), isTrue);
    expect(indexes.map((row) => row['name']), contains('idx_players_name_key'));
  });
}

Future<void> _createPlayersTable(
  Database database, {
  required bool withNameKey,
}) {
  final nameKeyColumn = withNameKey ? 'name_key TEXT NOT NULL,' : '';
  return database.execute('''
    CREATE TABLE players (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      $nameKeyColumn
      created_at INTEGER NOT NULL,
      is_present INTEGER NOT NULL
    )
  ''');
}

Future<void> _createMatchesTable(Database database) {
  return database.execute('''
    CREATE TABLE matches (
      id TEXT PRIMARY KEY,
      played_at INTEGER NOT NULL,
      match_mode TEXT NOT NULL,
      t1p1 TEXT NOT NULL,
      t1p2 TEXT NOT NULL,
      t2p1 TEXT NOT NULL,
      t2p2 TEXT NOT NULL,
      t1_score INTEGER NOT NULL,
      t2_score INTEGER NOT NULL,
      winning_team INTEGER NOT NULL,
      scorer_ids_json TEXT NOT NULL,
      is_rivalry INTEGER NOT NULL DEFAULT 0
    )
  ''');
}

Future<void> _createLegacyPlayersNameIndex(Database database) {
  return database.execute(
    'CREATE UNIQUE INDEX idx_players_name_nocase '
    'ON players(TRIM(name) COLLATE NOCASE)',
  );
}

Future<void> _insertPlayer(
  Database database, {
  required String id,
  required String name,
  required int createdAt,
  required bool withNameKey,
}) {
  return database.insert(
    'players',
    _playerRow(
      id: id,
      name: name,
      createdAt: createdAt,
      withNameKey: withNameKey,
    ),
  );
}

Map<String, Object?> _playerRow({
  required String id,
  required String name,
  required int createdAt,
  required bool withNameKey,
}) {
  return {
    'id': id,
    'name': name,
    if (withNameKey) 'name_key': Player.normalizedNameKey(name),
    'created_at': createdAt,
    'is_present': 1,
  };
}

Future<void> _insertMatch(
  Database database, {
  required String id,
  required String t1p1,
  required String t1p2,
  required String t2p1,
  required String t2p2,
  required List<String> scorerIds,
}) {
  return database.insert('matches', {
    'id': id,
    'played_at': 10,
    'match_mode': '2v2',
    't1p1': t1p1,
    't1p2': t1p2,
    't2p1': t2p1,
    't2p2': t2p2,
    't1_score': 3,
    't2_score': 1,
    'winning_team': 1,
    'scorer_ids_json': jsonEncode(scorerIds),
    'is_rivalry': 0,
  });
}
