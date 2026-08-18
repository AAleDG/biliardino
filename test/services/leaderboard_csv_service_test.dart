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
          'posizione,giocatore,punti,partite,vittorie,sconfitte,gol,'
              'win_rate,striscia_vittorie',
          '1,"Rossi, ""Ale""",9,4,3,1,12,0.750,2',
        ].join('\n'),
      );
    });
  });
}
