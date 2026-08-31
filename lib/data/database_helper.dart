import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/game_match.dart';
import '../models/player.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _db;

  static const databaseVersion = 7;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async => openDatabase(
    join(await getDatabasesPath(), 'biliardino.db'),
    version: databaseVersion,
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
    await _createSettingsTable(db);
    await _createIndexes(db);
    await _createMatchIntegrityTriggers(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await migrateDatabase(db, oldVersion, newVersion);
  }

  static Future<void> migrateDatabase(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
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
    if (oldVersion < 6) {
      await _createSettingsTable(db);
    }
    if (oldVersion < 7) {
      await _validateIntegrity(db);
      await _createIndexes(db);
      await _createMatchIntegrityTriggers(db);
    }
  }

  static Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_matches_played_at ON matches(played_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_matches_mode ON matches(match_mode)',
    );
    for (final column in const ['t1p1', 't1p2', 't2p1', 't2p2']) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_matches_$column ON matches($column)',
      );
    }
    await _createPlayersNameIndex(db);
  }

  static Future<void> migratePlayersToUniqueNames(DatabaseExecutor db) async {
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

  static Future<void> migratePlayersToPersistedNameKeys(
    DatabaseExecutor db,
  ) async {
    final hasNameKey = await _hasColumn(
      db,
      table: 'players',
      column: 'name_key',
    );
    final players = await db.query('players');
    await db.execute('DROP INDEX IF EXISTS idx_players_name_key');
    await db.execute('''
      CREATE TABLE players_new (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_key TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_present INTEGER NOT NULL
      )
    ''');
    for (final row in players) {
      final player = _PlayerRow.fromMap(row);
      await db.insert('players_new', {
        'id': player.id,
        'name': player.name,
        'name_key': hasNameKey && row['name_key'] is String
            ? row['name_key']
            : Player.normalizedNameKey(player.name),
        'created_at': row['created_at'],
        'is_present': row['is_present'],
      });
    }
    await db.execute('DROP TABLE players');
    await db.execute('ALTER TABLE players_new RENAME TO players');
  }

  static Future<void> migratePlayersToPersistedUniqueNameKeys(
    DatabaseExecutor db,
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

  Future<Map<String, String>> getSettings(List<String> keys) async {
    final db = await _database;
    if (keys.isEmpty) {
      return const {};
    }
    final placeholders = List.filled(keys.length, '?').join(', ');
    final rows = await db.query(
      'settings',
      columns: const ['key', 'value'],
      where: 'key IN ($placeholders)',
      whereArgs: keys,
    );
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }

  Future<void> setSettings(Map<String, String> values) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final entry in values.entries) {
        await txn.insert('settings', {
          'key': entry.key,
          'value': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}

Future<void> _validateIntegrity(DatabaseExecutor db) async {
  final playerRows = await db.query('players', columns: const ['id']);
  final playerIds = playerRows
      .map((row) => row['id'])
      .whereType<String>()
      .toSet();
  final matches = await db.query('matches');

  for (final match in matches) {
    final matchId = match['id'];
    final score1 = match['t1_score'];
    final score2 = match['t2_score'];
    final winningTeam = match['winning_team'];
    if (score1 is! int || score2 is! int || score1 < 0 || score2 < 0) {
      throw StateError('Invalid scores in match id=$matchId.');
    }
    if (score1 == score2 ||
        winningTeam is! int ||
        winningTeam != (score1 > score2 ? 1 : 2)) {
      throw StateError('Invalid winner in match id=$matchId.');
    }

    final mode = match['match_mode'];
    if (mode != '1v1' && mode != '2v2') {
      throw StateError('Invalid mode in match id=$matchId.');
    }
    final requiredPlayerColumns = mode == '1v1'
        ? const ['t1p1', 't2p1']
        : const ['t1p1', 't1p2', 't2p1', 't2p2'];
    if (mode == '1v1' && (match['t1p2'] != '' || match['t2p2'] != '')) {
      throw StateError('Invalid secondary players in match id=$matchId.');
    }
    final referencedPlayers = requiredPlayerColumns
        .map((column) => match[column])
        .whereType<String>()
        .toList();
    if (referencedPlayers.length != requiredPlayerColumns.length ||
        referencedPlayers.any((id) => !playerIds.contains(id)) ||
        referencedPlayers.toSet().length != referencedPlayers.length) {
      throw StateError('Invalid player references in match id=$matchId.');
    }

    final scorerJson = match['scorer_ids_json'];
    Object? decodedScorers;
    try {
      decodedScorers = jsonDecode(scorerJson is String ? scorerJson : '');
    } on FormatException {
      throw StateError('Invalid scorer history in match id=$matchId.');
    }
    if (decodedScorers is! List ||
        decodedScorers.any(
          (scorer) => scorer is! String || !referencedPlayers.contains(scorer),
        )) {
      throw StateError('Invalid scorer history in match id=$matchId.');
    }
    if (decodedScorers.isNotEmpty) {
      final team1 = {match['t1p1'], if (mode == '2v2') match['t1p2']};
      final team2 = {match['t2p1'], if (mode == '2v2') match['t2p2']};
      final team1Goals = decodedScorers.where(team1.contains).length;
      final team2Goals = decodedScorers.where(team2.contains).length;
      if (team1Goals != score1 || team2Goals != score2) {
        throw StateError('Scorer history does not match match id=$matchId.');
      }
    }
  }
}

Future<void> _createMatchIntegrityTriggers(DatabaseExecutor db) async {
  for (final operation in const ['INSERT', 'UPDATE']) {
    final triggerName = operation.toLowerCase();
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS validate_matches_$triggerName
      BEFORE $operation ON matches
      BEGIN
        SELECT CASE
          WHEN typeof(NEW.t1_score) != 'integer'
            OR typeof(NEW.t2_score) != 'integer'
            OR NEW.t1_score < 0 OR NEW.t2_score < 0 OR NEW.t1_score = NEW.t2_score
          THEN RAISE(ABORT, 'invalid match scores')
          WHEN NEW.winning_team NOT IN (1, 2)
            OR NEW.winning_team != CASE WHEN NEW.t1_score > NEW.t2_score THEN 1 ELSE 2 END
          THEN RAISE(ABORT, 'invalid match winner')
          WHEN NEW.match_mode NOT IN ('1v1', '2v2')
          THEN RAISE(ABORT, 'invalid match mode')
          WHEN NEW.match_mode = '1v1' AND (NEW.t1p2 != '' OR NEW.t2p2 != '')
          THEN RAISE(ABORT, 'invalid 1v1 secondary player reference')
          WHEN NOT EXISTS (SELECT 1 FROM players WHERE id = NEW.t1p1)
            OR NOT EXISTS (SELECT 1 FROM players WHERE id = NEW.t2p1)
            OR (NEW.match_mode = '2v2' AND NOT EXISTS (SELECT 1 FROM players WHERE id = NEW.t1p2))
            OR (NEW.match_mode = '2v2' AND NOT EXISTS (SELECT 1 FROM players WHERE id = NEW.t2p2))
          THEN RAISE(ABORT, 'invalid match player reference')
          WHEN NEW.t1p1 = NEW.t2p1
            OR (NEW.match_mode = '2v2' AND (
              NEW.t1p1 IN (NEW.t1p2, NEW.t2p2)
              OR NEW.t2p1 IN (NEW.t1p2, NEW.t2p2)
              OR NEW.t1p2 = NEW.t2p2
            ))
          THEN RAISE(ABORT, 'duplicate match player reference')
          WHEN json_valid(NEW.scorer_ids_json) = 0
            OR json_type(NEW.scorer_ids_json) != 'array'
          THEN RAISE(ABORT, 'invalid scorer history')
          WHEN EXISTS (
            SELECT 1 FROM json_each(NEW.scorer_ids_json)
            WHERE type != 'text'
              OR value NOT IN (NEW.t1p1, NEW.t2p1,
                CASE WHEN NEW.match_mode = '2v2' THEN NEW.t1p2 ELSE '' END,
                CASE WHEN NEW.match_mode = '2v2' THEN NEW.t2p2 ELSE '' END)
          )
          THEN RAISE(ABORT, 'invalid scorer player reference')
          WHEN json_array_length(NEW.scorer_ids_json) > 0 AND (
            (SELECT COUNT(*) FROM json_each(NEW.scorer_ids_json)
              WHERE value IN (NEW.t1p1,
                CASE WHEN NEW.match_mode = '2v2' THEN NEW.t1p2 ELSE '' END)) != NEW.t1_score
            OR (SELECT COUNT(*) FROM json_each(NEW.scorer_ids_json)
              WHERE value IN (NEW.t2p1,
                CASE WHEN NEW.match_mode = '2v2' THEN NEW.t2p2 ELSE '' END)) != NEW.t2_score
          )
          THEN RAISE(ABORT, 'scorer history does not match scores')
        END;
      END
    ''');
  }
}

Future<void> _createSettingsTable(DatabaseExecutor db) {
  return db.execute('''
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
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
