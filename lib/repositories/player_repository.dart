import 'dart:async';

import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/player.dart';

class PlayerRepository {
  PlayerRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final DatabaseHelper _db;
  final Uuid _uuid;
  final StreamController<List<Player>> _controller =
      StreamController<List<Player>>.broadcast();
  List<Player> _cache = const [];

  List<Player> get players => _cache;

  Stream<List<Player>> watchPlayers() async* {
    yield _cache;
    yield* _controller.stream;
  }

  Future<void> load() async {
    _publish(await _db.getPlayers());
  }

  Future<void> addPlayer(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final player = Player(
      id: _uuid.v4(),
      name: trimmed,
      createdAt: DateTime.now(),
      isPresent: true,
    );
    await _db.insertPlayer(player);
    await _reload();
  }

  Future<void> togglePresent(Player p) async {
    await _db.updatePlayer(p.copyWith(isPresent: !p.isPresent));
    await _reload();
  }

  Future<void> _reload() async {
    _publish(await _db.getPlayers());
  }

  void _publish(List<Player> players) {
    _cache = List.unmodifiable(players);
    if (!_controller.isClosed) {
      _controller.add(_cache);
    }
  }

  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
