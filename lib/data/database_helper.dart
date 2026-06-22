import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/player.dart';
import '../models/game_match.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async =>
      openDatabase(join(await getDatabasesPath(), 'biliardino.db'),
          version: 1, onCreate: _onCreate);

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
        t1p1 TEXT NOT NULL,
        t1p2 TEXT NOT NULL,
        t2p1 TEXT NOT NULL,
        t2p2 TEXT NOT NULL,
        t1_score INTEGER NOT NULL,
        t2_score INTEGER NOT NULL,
        winning_team INTEGER NOT NULL
      )
    ''');
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
