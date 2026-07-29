import 'dart:convert';

enum MatchMode {
  oneVsOne('1v1', 1),
  twoVsTwo('2v2', 2);

  const MatchMode(this.dbValue, this.teamSize);

  final String dbValue;
  final int teamSize;

  static MatchMode fromDbValue(String? value) {
    return MatchMode.values.firstWhere(
      (mode) => mode.dbValue == value,
      orElse: () => MatchMode.twoVsTwo,
    );
  }
}

class GameMatch {
  final String id;
  final DateTime playedAt;
  final MatchMode mode;
  final String t1p1, t1p2, t2p1, t2p2;
  final int t1Score, t2Score;
  final int winningTeam;
  final List<String> scorerIds;

  GameMatch({
    required this.id,
    required this.playedAt,
    required this.mode,
    required this.t1p1,
    required this.t1p2,
    required this.t2p1,
    required this.t2p2,
    required this.t1Score,
    required this.t2Score,
    required this.winningTeam,
    required this.scorerIds,
  });

  List<String> get team1 => [t1p1, t1p2].where(_isPlayerId).toList();
  List<String> get team2 => [t2p1, t2p2].where(_isPlayerId).toList();
  List<String> get allPlayers => [...team1, ...team2];
  List<String> get winners => winningTeam == 1 ? team1 : team2;
  List<String> get losers => winningTeam == 1 ? team2 : team1;

  int goalsByPlayer(String playerId) =>
      scorerIds.where((id) => id == playerId).length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'played_at': playedAt.millisecondsSinceEpoch,
        'match_mode': mode.dbValue,
        't1p1': t1p1,
        't1p2': t1p2,
        't2p1': t2p1,
        't2p2': t2p2,
        't1_score': t1Score,
        't2_score': t2Score,
        'winning_team': winningTeam,
        'scorer_ids_json': jsonEncode(scorerIds),
      };

  factory GameMatch.fromMap(Map<String, dynamic> m) => GameMatch(
        id: m['id'] as String,
        playedAt: DateTime.fromMillisecondsSinceEpoch(m['played_at'] as int),
        mode: MatchMode.fromDbValue(m['match_mode'] as String?),
        t1p1: m['t1p1'] as String,
        t1p2: m['t1p2'] as String,
        t2p1: m['t2p1'] as String,
        t2p2: m['t2p2'] as String,
        t1Score: m['t1_score'] as int,
        t2Score: m['t2_score'] as int,
        winningTeam: m['winning_team'] as int,
        scorerIds: List<String>.from(
          jsonDecode((m['scorer_ids_json'] as String?) ?? '[]') as List,
        ),
      );

  static bool _isPlayerId(String value) => value.trim().isNotEmpty;
}
