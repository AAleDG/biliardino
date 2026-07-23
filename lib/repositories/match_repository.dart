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

  List<GameMatch> get matches => _cache;

  Stream<List<GameMatch>> watchMatches() async* {
    yield _cache;
    yield* _controller.stream;
  }

  Future<void> load() async {
    _publish(await _db.getMatches());
  }

  Future<void> addMatch({
    required List<String> team1,
    required List<String> team2,
    required int score1,
    required int score2,
  }) async {
    _validateMatch(
      team1: team1,
      team2: team2,
      score1: score1,
      score2: score2,
    );
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
    _publish(await _db.getMatches());
  }

  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void _publish(List<GameMatch> matches) {
    _cache = List.unmodifiable(matches);
    if (!_controller.isClosed) {
      _controller.add(_cache);
    }
  }

  void _validateMatch({
    required List<String> team1,
    required List<String> team2,
    required int score1,
    required int score2,
  }) {
    if (team1.length != 2 || team2.length != 2) {
      throw ArgumentError('Each team must contain exactly two players.');
    }
    final players = [...team1, ...team2];
    if (players.any((id) => id.trim().isEmpty) || players.toSet().length != 4) {
      throw ArgumentError('A match requires four distinct player IDs.');
    }
    if (score1 < 0 || score2 < 0) {
      throw ArgumentError('Scores cannot be negative.');
    }
    if (score1 == score2) {
      throw ArgumentError('A match must have one winning team.');
    }
  }
}
