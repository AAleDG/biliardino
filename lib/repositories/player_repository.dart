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
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Player name cannot be empty.');
    }
    _validateUniqueName(trimmed, ignoredPlayerId: null);
    if (await _db.playerNameExists(trimmed)) {
      throw ArgumentError.value(
        trimmed,
        'name',
        'A player with this name already exists.',
      );
    }
    final player = Player(
      id: _uuid.v4(),
      name: trimmed,
      createdAt: DateTime.now(),
      isPresent: true,
    );
    await _db.insertPlayer(player);
    await _reload();
  }

  Future<void> renamePlayer(Player player, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Player name cannot be empty.');
    }
    _validateUniqueName(trimmed, ignoredPlayerId: player.id);
    await _db.updatePlayer(player.copyWith(name: trimmed));
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

  void _validateUniqueName(String name, {required String? ignoredPlayerId}) {
    final normalized = Player.normalizedNameKey(name);
    final exists = _cache.any(
      (player) =>
          player.id != ignoredPlayerId &&
          Player.normalizedNameKey(player.name) == normalized,
    );
    if (exists) {
      throw ArgumentError.value(name, 'name', 'Player name already exists.');
    }
  }

  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
