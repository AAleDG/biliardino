import 'package:biliardino/data/database_helper.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  FakeDatabaseHelper({
    List<Player>? players,
    List<GameMatch>? matches,
  })  : players = players ?? const [],
        matches = matches ?? const [];

  final List<Player> players;
  final List<GameMatch> matches;
  int insertMatchCalls = 0;
  int updateMatchCalls = 0;
  int deleteMatchCalls = 0;
  int insertPlayerCalls = 0;
  int updatePlayerCalls = 0;

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
}
