import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/game_match.dart';
import '../models/player.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async =>
      openDatabase(join(await getDatabasesPath(), 'biliardino.db'),
        version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
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
  }

  Future<List<Player>> getPlayers() async {
    final db = await _database;
    final rows = await db.query('players', orderBy: 'name COLLATE NOCASE');
    return rows.map(Player.fromMap).toList();
  }

  Future<void> insertPlayer(Player p) async => (await _database).insert(
        'players',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> updatePlayer(Player p) async => (await _database)
      .update('players', p.toMap(), where: 'id = ?', whereArgs: [p.id]);

  Future<List<GameMatch>> getMatches() async {
    final db = await _database;
    final rows = await db.query('matches', orderBy: 'played_at DESC');
    return rows.map(GameMatch.fromMap).toList();
  }

  Future<void> insertMatch(GameMatch m) async => (await _database).insert(
        'matches',
        m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
}
