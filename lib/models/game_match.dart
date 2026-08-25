import 'dart:convert';

enum MatchMode {
  oneVsOne('1v1', 1),
  twoVsTwo('2v2', 2);

  const MatchMode(this.dbValue, this.teamSize);

  final String dbValue;
  final int teamSize;

  static MatchMode fromDbValue(String? value) {
    if (value == 'rivalry') {
      return MatchMode.oneVsOne;
    }
    for (final mode in MatchMode.values) {
      if (mode.dbValue == value) {
        return mode;
      }
    }
    throw FormatException('Unknown match_mode value: $value');
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
  final bool isRivalry;

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
    this.isRivalry = false,
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
        'is_rivalry': isRivalry ? 1 : 0,
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
        isRivalry: (m['is_rivalry'] as int?) == 1 ||
            (m['match_mode'] as String?) == 'rivalry',
      );

  GameMatch copyWith({
    DateTime? playedAt,
    MatchMode? mode,
    String? t1p1,
    String? t1p2,
    String? t2p1,
    String? t2p2,
    int? t1Score,
    int? t2Score,
    int? winningTeam,
    List<String>? scorerIds,
    bool? isRivalry,
  }) {
    return GameMatch(
      id: id,
      playedAt: playedAt ?? this.playedAt,
      mode: mode ?? this.mode,
      t1p1: t1p1 ?? this.t1p1,
      t1p2: t1p2 ?? this.t1p2,
      t2p1: t2p1 ?? this.t2p1,
      t2p2: t2p2 ?? this.t2p2,
      t1Score: t1Score ?? this.t1Score,
      t2Score: t2Score ?? this.t2Score,
      winningTeam: winningTeam ?? this.winningTeam,
      scorerIds: scorerIds ?? this.scorerIds,
      isRivalry: isRivalry ?? this.isRivalry,
    );
  }

  static bool _isPlayerId(String value) => value.trim().isNotEmpty;
}
