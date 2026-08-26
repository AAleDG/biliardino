import 'package:biliardino/data/database_helper.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  FakeDatabaseHelper({List<Player>? players, List<GameMatch>? matches})
    : players = players ?? const [],
      matches = matches ?? const [];

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
  }

  @override
  Future<void> insertPlayer(Player player) async {
    insertPlayerCalls++;
  }

  @override
  Future<bool> playerNameExists(String name) async => hasDuplicatePlayerName;

  @override
  Future<void> updatePlayer(Player player) async {
    updatePlayerCalls++;
  }

  @override
  Future<void> updateMatch(GameMatch match) async {
    updateMatchCalls++;
  }

  @override
  Future<void> deleteMatch(String id) async {
    deleteMatchCalls++;
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
