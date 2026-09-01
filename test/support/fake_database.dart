import 'package:biliardino/data/database_helper.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  FakeDatabaseHelper({List<Player>? players, List<GameMatch>? matches})
      : players = List<Player>.from(players ?? const []),
        matches = List<GameMatch>.from(matches ?? const []);

  final List<Player> players;
  final List<GameMatch> matches;
  int insertMatchCalls = 0;
  int updateMatchCalls = 0;
  int deleteMatchCalls = 0;
  int insertPlayerCalls = 0;
  int updatePlayerCalls = 0;
  bool hasDuplicatePlayerName = false;
  final Map<String, String> settings = {};

  @override
  Future<List<Player>> getPlayers() async => players;

  @override
  Future<List<GameMatch>> getMatches() async => matches;

  @override
  Future<void> insertMatch(GameMatch match) async {
    insertMatchCalls++;
    matches.insert(0, match);
  }

  @override
  Future<void> insertPlayer(Player player) async {
    insertPlayerCalls++;
    players.add(player);
  }

  @override
  Future<bool> playerNameExists(String name) async => hasDuplicatePlayerName;

  @override
  Future<void> updatePlayer(Player player) async {
    updatePlayerCalls++;
    final index = players.indexWhere((candidate) => candidate.id == player.id);
    if (index >= 0) players[index] = player;
  }

  @override
  Future<void> updateMatch(GameMatch match) async {
    updateMatchCalls++;
    final index = matches.indexWhere((candidate) => candidate.id == match.id);
    if (index >= 0) {
      matches[index] = match;
    }
  }

  @override
  Future<void> deleteMatch(String id) async {
    deleteMatchCalls++;
    matches.removeWhere((match) => match.id == id);
  }

  @override
  Future<Map<String, String>> getSettings(List<String> keys) async {
    return {
      for (final key in keys)
        if (settings.containsKey(key)) key: settings[key]!,
    };
  }

  @override
  Future<void> setSettings(Map<String, String> values) async {
    settings.addAll(values);
  }
}
