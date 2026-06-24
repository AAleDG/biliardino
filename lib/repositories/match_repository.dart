import 'dart:async';

import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/game_match.dart';

class MatchRepository {
  MatchRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final DatabaseHelper _db;
  final Uuid _uuid;
  final StreamController<List<GameMatch>> _controller =
      StreamController<List<GameMatch>>.broadcast();
  List<GameMatch> _cache = const [];

  List<GameMatch> get matches => List.unmodifiable(_cache);

  Stream<List<GameMatch>> watchMatches() async* {
    yield _cache;
    yield* _controller.stream;
  }

  Future<void> load() async {
    _cache = await _db.getMatches();
    _controller.add(_cache);
  }

  Future<void> addMatch({
    required List<String> team1,
    required List<String> team2,
    required int score1,
    required int score2,
  }) async {
    final match = GameMatch(
      id: _uuid.v4(),
      playedAt: DateTime.now(),
      t1p1: team1[0],
      t1p2: team1[1],
      t2p1: team2[0],
      t2p2: team2[1],
      t1Score: score1,
      t2Score: score2,
      winningTeam: score1 > score2 ? 1 : 2,
    );
    await _db.insertMatch(match);
    _cache = await _db.getMatches();
    _controller.add(_cache);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
