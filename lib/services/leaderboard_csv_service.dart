import '../models/player_stats.dart';

class LeaderboardCsvService {
  const LeaderboardCsvService._();

  static String build(List<PlayerStats> stats) {
    final rows = <List<String>>[
      const [
        'Posizione',
        'Giocatore',
        'Punti',
        'Partite',
        'Vittorie',
        'Sconfitte',
        'Gol',
        'Win rate',
        'Striscia vittorie',
      ],
      ...stats.asMap().entries.map((entry) {
        final stats = entry.value;
        return [
          '${entry.key + 1}',
          stats.player.name,
          '${stats.points}',
          '${stats.games}',
          '${stats.wins}',
          '${stats.losses}',
          '${stats.goalsScored}',
          '${(stats.winRate * 100).toStringAsFixed(1)}%',
          '${stats.currentWinStreak}',
        ];
      }),
    ];
    return rows.map(_encodeRow).join('\n');
  }
}

String _encodeRow(List<String> row) {
  return row.map(_encodeCell).join(',');
}

String _encodeCell(String value) {
  final sanitized = _sanitizeFormula(value);
  final escaped = sanitized.replaceAll('"', '""');
  return '"$escaped"';
}

String _sanitizeFormula(String value) {
  if (value.isEmpty) {
    return value;
  }
  const formulaPrefixes = {'=', '+', '-', '@'};
  if (formulaPrefixes.contains(value[0])) {
    return "'$value";
  }
  return value;
}
