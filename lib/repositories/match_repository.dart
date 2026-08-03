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
    required MatchMode mode,
    required bool isRivalry,
    required List<String> team1,
    required List<String> team2,
    required int score1,
    required int score2,
    required List<String> scorerIds,
  }) async {
    _validateMatch(
      mode: mode,
      team1: team1,
      team2: team2,
      score1: score1,
      score2: score2,
      scorerIds: scorerIds,
    );
    final match = GameMatch(
      id: _uuid.v4(),
      playedAt: DateTime.now(),
      mode: mode,
      isRivalry: isRivalry,
      t1p1: team1[0],
      t1p2: team1.length > 1 ? team1[1] : '',
      t2p1: team2[0],
      t2p2: team2.length > 1 ? team2[1] : '',
      t1Score: score1,
      t2Score: score2,
      winningTeam: score1 > score2 ? 1 : 2,
      scorerIds: List.unmodifiable(scorerIds),
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
    required MatchMode mode,
    required List<String> team1,
    required List<String> team2,
    required int score1,
    required int score2,
    required List<String> scorerIds,
  }) {
    if (team1.length != mode.teamSize || team2.length != mode.teamSize) {
      throw ArgumentError('Each team must contain exactly ${mode.teamSize} players.');
    }
    final players = [...team1, ...team2];
    final expectedPlayers = mode.teamSize * 2;
    if (players.any((id) => id.trim().isEmpty) ||
        players.toSet().length != expectedPlayers) {
      throw ArgumentError('A match requires $expectedPlayers distinct player IDs.');
    }
    if (score1 < 0 || score2 < 0) {
      throw ArgumentError('Scores cannot be negative.');
    }
    if (score1 == score2) {
      throw ArgumentError('A match must have one winning team.');
    }

    final team1Set = team1.toSet();
    final team2Set = team2.toSet();
    var team1Goals = 0;
    var team2Goals = 0;
    for (final scorerId in scorerIds) {
      if (team1Set.contains(scorerId)) {
        team1Goals += 1;
        continue;
      }
      if (team2Set.contains(scorerId)) {
        team2Goals += 1;
        continue;
      }
      throw ArgumentError('Every scorer must belong to one of the two teams.');
    }
    if (team1Goals != score1 || team2Goals != score2) {
      throw ArgumentError('Scorer history must match the final score.');
    }
  }
}
