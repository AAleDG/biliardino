import 'package:biliardino/models/player.dart';
import 'package:biliardino/models/player_stats.dart';
import 'package:biliardino/services/leaderboard_csv_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeaderboardCsvService', () {
    test('serializes rankings with escaped values', () {
      final csv = LeaderboardCsvService.build([
        PlayerStats(
          player: Player(
            id: 'p1',
            name: 'Rossi, "Ale"',
            createdAt: DateTime(2026),
            isPresent: true,
          ),
          games: 4,
          wins: 3,
          losses: 1,
          goalsScored: 12,
          currentWinStreak: 2,
        ),
      ]);

      expect(
        csv,
        [
          '"Posizione","Giocatore","Punti","Partite","Vittorie",'
              '"Sconfitte","Gol","Win rate","Striscia vittorie"',
          '"1","Rossi, ""Ale""","9","4","3","1","12","75.0%","2"',
        ].join('\n'),
      );
    });

    test('sanitizes player names that spreadsheet apps treat as formulas', () {
      final csv = LeaderboardCsvService.build([
        _stats('p1', '=cmd'),
        _stats('p2', '+sum'),
        _stats('p3', '-10'),
        _stats('p4', '@name'),
      ]);

      expect(csv, contains("\"'=cmd\""));
      expect(csv, contains("\"'+sum\""));
      expect(csv, contains("\"'-10\""));
      expect(csv, contains("\"'@name\""));
    });

    test('quotes cells and keeps safe names unchanged', () {
      final csv = LeaderboardCsvService.build([
        _stats('p1', 'Mario "Ace", Rossi'),
      ]);

      expect(
        csv.split('\n').last,
        '"1","Mario ""Ace"", Rossi","3","2","1","1","4","50.0%","0"',
      );
    });
  });
}

PlayerStats _stats(String id, String name) {
  return PlayerStats(
    player: Player(
      id: id,
      name: name,
      createdAt: DateTime(2026),
      isPresent: true,
    ),
    games: 2,
    wins: 1,
    losses: 1,
    goalsScored: 4,
  );
}
