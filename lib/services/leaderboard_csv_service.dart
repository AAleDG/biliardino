import '../models/player_stats.dart';
import '../models/team_leaderboard_stats.dart';

class LeaderboardCsvService {
  const LeaderboardCsvService._();

  static String build(List<PlayerStats> stats) => _build(
    'Giocatore',
    stats.map(
      (s) => (
        s.player.name,
        s.points,
        s.games,
        s.wins,
        s.losses,
        s.goalsScored,
        s.winRate,
        s.currentWinStreak,
      ),
    ),
  );

  static String buildPairs(List<TeamLeaderboardStats> stats) => _build(
    'Coppia',
    stats.map(
      (s) => (
        s.name,
        s.points,
        s.games,
        s.wins,
        s.losses,
        s.goalsScored,
        s.winRate,
        s.currentWinStreak,
      ),
    ),
  );

  static String _build(
    String identityLabel,
    Iterable<(String, int, int, int, int, int, double, int)> stats,
  ) {
    final rows = <List<String>>[
      [
        'Posizione',
        identityLabel,
        'Punti',
        'Partite',
        'Vittorie',
        'Sconfitte',
        'Gol',
        'Win rate',
        'Striscia vittorie',
      ],
      for (final (index, s) in stats.indexed)
        [
          '${index + 1}',
          s.$1,
          '${s.$2}',
          '${s.$3}',
          '${s.$4}',
          '${s.$5}',
          '${s.$6}',
          '${(s.$7 * 100).toStringAsFixed(1)}%',
          '${s.$8}',
        ],
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
