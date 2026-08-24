import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/game_match.dart';
import '../models/player.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async => openDatabase(
    join(await getDatabasesPath(), 'biliardino.db'),
    version: 5,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_key TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_present INTEGER NOT NULL
      )
    ''');
    await db.execute('''
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
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE matches ADD COLUMN match_mode TEXT NOT NULL DEFAULT '2v2'",
      );
      await db.execute(
        "ALTER TABLE matches ADD COLUMN scorer_ids_json TEXT NOT NULL DEFAULT '[]'",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE matches ADD COLUMN is_rivalry INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        "UPDATE matches SET is_rivalry = 1 WHERE match_mode = 'rivalry'",
      );
      await db.execute(
        "UPDATE matches SET match_mode = '1v1' WHERE match_mode = 'rivalry'",
      );
    }
    if (oldVersion < 4) {
      await migratePlayersToUniqueNames(db);
    }
    if (oldVersion < 5) {
      await migratePlayersToPersistedUniqueNameKeys(db);
    }
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_matches_played_at ON matches(played_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_matches_mode ON matches(match_mode)',
    );
    await _createPlayersNameIndex(db);
  }

  static Future<void> migratePlayersToUniqueNames(Database db) async {
    final players = await db.query('players');
    final renamedPlayers = _uniquePlayerNames(players);
    for (final player in renamedPlayers) {
      await db.update(
        'players',
        {
          'name': player.name,
          if (await _hasColumn(db, table: 'players', column: 'name_key'))
            'name_key': Player.normalizedNameKey(player.name),
        },
        where: 'id = ?',
        whereArgs: [player.id],
      );
    }
  }

  static Future<void> migratePlayersToPersistedNameKeys(Database db) async {
    final hasNameKey = await _hasColumn(
      db,
      table: 'players',
      column: 'name_key',
    );
    if (!hasNameKey) {
      await db.execute("ALTER TABLE players ADD COLUMN name_key TEXT");
    }

    final players = await db.query('players');
    for (final row in players) {
      final player = _PlayerRow.fromMap(row);
      await db.update(
        'players',
        {'name_key': Player.normalizedNameKey(player.name)},
        where: 'id = ?',
        whereArgs: [player.id],
      );
    }
  }

  static Future<void> migratePlayersToPersistedUniqueNameKeys(
    Database db,
  ) async {
    await migratePlayersToPersistedNameKeys(db);
    await migratePlayersToUniqueNames(db);
    await _dropLegacyPlayersNameIndex(db);
    await _createIndexes(db);
  }

  Future<List<Player>> getPlayers() async {
    final db = await _database;
    final rows = await db.query('players', orderBy: 'name COLLATE NOCASE');
    return rows.map(Player.fromMap).toList();
  }

  Future<bool> playerNameExists(String name) async {
    final rows = await (await _database).query(
      'players',
      columns: const ['id'],
      where: 'name_key = ?',
      whereArgs: [Player.normalizedNameKey(name)],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> insertPlayer(Player p) async =>
      (await _database).insert('players', p.toMap());

  Future<void> updatePlayer(Player p) async {
    final updatedRows = await (await _database).update(
      'players',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
    if (updatedRows != 1) {
      throw StateError(
        'Player update failed for id=${p.id}. Rows: $updatedRows',
      );
    }
  }

  Future<List<GameMatch>> getMatches() async {
    final db = await _database;
    final rows = await db.query('matches', orderBy: 'played_at DESC');
    return rows.map(GameMatch.fromMap).toList();
  }

  Future<void> insertMatch(GameMatch m) async => (await _database).insert(
    'matches',
    m.toMap(),
    conflictAlgorithm: ConflictAlgorithm.abort,
  );

  Future<void> updateMatch(GameMatch m) async {
    final updatedRows = await (await _database).update(
      'matches',
      m.toMap(),
      where: 'id = ?',
      whereArgs: [m.id],
    );
    if (updatedRows != 1) {
      throw StateError(
        'Match update failed for id=${m.id}. Rows: $updatedRows',
      );
    }
  }

  Future<void> deleteMatch(String id) async {
    final deletedRows = await (await _database).delete(
      'matches',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedRows != 1) {
      throw StateError('Match delete failed for id=$id. Rows: $deletedRows');
    }
  }
}

Future<void> _createPlayersNameIndex(DatabaseExecutor db) {
  return db.execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_players_name_key '
    'ON players(name_key)',
  );
}

Future<void> _dropLegacyPlayersNameIndex(DatabaseExecutor db) {
  return db.execute('DROP INDEX IF EXISTS idx_players_name_nocase');
}

Future<bool> _hasColumn(
  DatabaseExecutor db, {
  required String table,
  required String column,
}) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.any((row) => row['name'] == column);
}

List<_PlayerRow> _uniquePlayerNames(List<Map<String, Object?>> players) {
  final groups = <String, List<_PlayerRow>>{};
  for (final row in players) {
    final player = _PlayerRow.fromMap(row);
    final normalizedName = Player.normalizedNameKey(player.name);
    groups.putIfAbsent(normalizedName, () => []).add(player);
  }

  final renamedPlayers = <_PlayerRow>[];
  final usedNames = groups.keys.toSet();
  final sortedGroupEntries = groups.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in sortedGroupEntries) {
    final group = entry.value;
    if (group.length < 2) {
      continue;
    }
    usedNames.remove(entry.key);
    final sorted = [...group]
      ..sort((a, b) {
        final byCreatedAt = a.createdAt.compareTo(b.createdAt);
        if (byCreatedAt != 0) {
          return byCreatedAt;
        }
        return a.id.compareTo(b.id);
      });
    final baseName = sorted.first.name.trim();
    for (var index = 0; index < sorted.length; index += 1) {
      final player = sorted[index];
      final candidateName = index == 0
          ? _nextAvailableName(
              baseName: baseName,
              startSuffix: 1,
              usedNames: usedNames,
            )
          : _nextAvailableName(
              baseName: baseName,
              startSuffix: index + 1,
              usedNames: usedNames,
            );
      usedNames.add(Player.normalizedNameKey(candidateName));
      if (candidateName != player.name) {
        renamedPlayers.add(player.copyWith(name: candidateName));
      }
    }
  }
  return renamedPlayers;
}

String _nextAvailableName({
  required String baseName,
  required int startSuffix,
  required Set<String> usedNames,
}) {
  if (startSuffix == 1 &&
      !usedNames.contains(Player.normalizedNameKey(baseName))) {
    return baseName;
  }
  var suffix = startSuffix < 2 ? 2 : startSuffix;
  while (true) {
    final candidateName = '$baseName ($suffix)';
    if (!usedNames.contains(Player.normalizedNameKey(candidateName))) {
      return candidateName;
    }
    suffix += 1;
  }
}

class _PlayerRow {
  const _PlayerRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int createdAt;

  _PlayerRow copyWith({required String name}) {
    return _PlayerRow(id: id, name: name, createdAt: createdAt);
  }

  factory _PlayerRow.fromMap(Map<String, Object?> map) {
    return _PlayerRow(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] as int,
    );
  }
}
