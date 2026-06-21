import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/database_helper.dart';
import '../models/player.dart';
import '../models/game_match.dart';

class PlayerStats {
  final Player player;
  final int games, wins, losses;
  PlayerStats({
    required this.player,
    required this.games,
    required this.wins,
    required this.losses,
  });

  int get points => wins * 3;
  double get winRate => games == 0 ? 0 : wins / games;
}

class AppState extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  bool isLoading = true;
  List<Player> players = [];
  List<GameMatch> matches = [];

  Future<void> init() async {
    await _reload();
    isLoading = false;
    notifyListeners();
  }

  Future<void> _reload() async {
    players = await _db.getPlayers();
    matches = await _db.getMatches();
  }

  List<GameMatch> get matchesSorted =>
      [...matches]..sort((a, b) => b.playedAt.compareTo(a.playedAt));

  String playerName(String id) => players
      .firstWhere(
        (p) => p.id == id,
        orElse: () => Player(id: id, name: '—', createdAt: DateTime.now()),
      )
      .name;

  Future<void> addPlayer(String name) async {
    final p = Player(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      isPresent: true,
    );
    await _db.insertPlayer(p);
    await _reload();
    notifyListeners();
  }

  Future<void> togglePresent(Player p) async {
    await _db.updatePlayer(p.copyWith(isPresent: !p.isPresent));
    await _reload();
    notifyListeners();
  }

  Future<void> addMatch({
    required List<String> team1,
    required List<String> team2,
    required int score1,
    required int score2,
  }) async {
    final m = GameMatch(
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
    await _db.insertMatch(m);
    await _reload();
    notifyListeners();
  }

  List<GameMatch> matchesForPlayer(String id) =>
      matchesSorted.where((m) => m.allPlayers.contains(id)).toList();

  List<PlayerStats> leaderboard() {
    final wins = <String, int>{};
    final games = <String, int>{};
    for (final p in players) {
      wins[p.id] = 0;
      games[p.id] = 0;
    }
    for (final m in matches) {
      for (final id in m.allPlayers) {
        games[id] = (games[id] ?? 0) + 1;
      }
      for (final id in m.winners) {
        wins[id] = (wins[id] ?? 0) + 1;
      }
    }
    final list = players.map((p) {
      final g = games[p.id] ?? 0;
      final w = wins[p.id] ?? 0;
      return PlayerStats(player: p, games: g, wins: w, losses: g - w);
    }).toList();

    list.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      final byRate = b.winRate.compareTo(a.winRate);
      if (byRate != 0) return byRate;
      return a.player.name.toLowerCase().compareTo(b.player.name.toLowerCase());
    });
    return list;
  }
}
