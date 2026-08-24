import 'dart:convert';

import 'package:biliardino/data/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_present INTEGER NOT NULL
      )
    ''');
    await database.execute('''
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
  });

  tearDown(() async {
    await database.close();
  });

  test('migrates duplicate player names without losing match history',
      () async {
    await _insertPlayer(
      database,
      id: 'old',
      name: 'Mario',
      createdAt: 1,
    );
    await _insertPlayer(
      database,
      id: 'busy',
      name: 'mario',
      createdAt: 2,
    );
    await _insertPlayer(
      database,
      id: 'other',
      name: 'Luigi',
      createdAt: 3,
    );
    await _insertMatch(
      database,
      id: 'm1',
      t1p1: 'busy',
      t1p2: 'other',
      t2p1: 'p3',
      t2p2: 'p4',
      scorerIds: const ['busy', 'busy', 'busy', 'old'],
    );
    await _insertMatch(
      database,
      id: 'm2',
      t1p1: 'old',
      t1p2: 'other',
      t2p1: 'p3',
      t2p2: 'p4',
      scorerIds: const ['old'],
    );

    await DatabaseHelper.migratePlayersToUniqueNames(database);

    final players = await database.query('players', orderBy: 'id');
    final matches = await database.query('matches', orderBy: 'id');

    expect(players.map((row) => row['id']), ['busy', 'other']);
    expect(matches[0]['t1p1'], 'busy');
    expect(matches[0]['scorer_ids_json'], '["busy","busy","busy","busy"]');
    expect(matches[1]['t1p1'], 'busy');
    expect(matches[1]['scorer_ids_json'], '["busy"]');
    await expectLater(
      database.insert(
        'players',
        {
          'id': 'new',
          'name': ' MARIO ',
          'created_at': 4,
          'is_present': 1,
        },
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

}

Future<void> _insertPlayer(
  Database database, {
  required String id,
  required String name,
  required int createdAt,
}) {
  return database.insert('players', {
    'id': id,
    'name': name,
    'created_at': createdAt,
    'is_present': 1,
  });
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
