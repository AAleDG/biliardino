import '../models/player_stats.dart';

class LeaderboardCsvService {
  const LeaderboardCsvService._();

  static String build(List<PlayerStats> stats) {
    final rows = [
      [
        'posizione',
        'giocatore',
        'punti',
        'partite',
        'vittorie',
        'sconfitte',
        'gol',
        'win_rate',
        'striscia_vittorie',
      ],
      ...stats.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final stat = entry.value;
        return [
          '$rank',
          stat.player.name,
          '${stat.points}',
          '${stat.games}',
          '${stat.wins}',
          '${stat.losses}',
          '${stat.goalsScored}',
          stat.winRate.toStringAsFixed(3),
          '${stat.currentWinStreak}',
        ];
      }),
    ];
    return rows.map(_serializeRow).join('\n');
  }

  static String _serializeRow(List<String> values) {
    return values.map(_serializeValue).join(',');
  }

  static String _serializeValue(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r')) {
      return '"$escaped"';
    }
    return escaped;
  }
}
