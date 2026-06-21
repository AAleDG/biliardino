class GameMatch {
  final String id;
  final DateTime playedAt;
  final String t1p1, t1p2, t2p1, t2p2;
  final int t1Score, t2Score;
  final int winningTeam;

  GameMatch({
    required this.id,
    required this.playedAt,
    required this.t1p1,
    required this.t1p2,
    required this.t2p1,
    required this.t2p2,
    required this.t1Score,
    required this.t2Score,
    required this.winningTeam,
  });

  List<String> get team1 => [t1p1, t1p2];
  List<String> get team2 => [t2p1, t2p2];
  List<String> get allPlayers => [t1p1, t1p2, t2p1, t2p2];
  List<String> get winners => winningTeam == 1 ? team1 : team2;
  List<String> get losers => winningTeam == 1 ? team2 : team1;

  Map<String, dynamic> toMap() => {
        'id': id,
        'played_at': playedAt.millisecondsSinceEpoch,
        't1p1': t1p1,
        't1p2': t1p2,
        't2p1': t2p1,
        't2p2': t2p2,
        't1_score': t1Score,
        't2_score': t2Score,
        'winning_team': winningTeam,
      };

  factory GameMatch.fromMap(Map<String, dynamic> m) => GameMatch(
        id: m['id'] as String,
        playedAt: DateTime.fromMillisecondsSinceEpoch(m['played_at'] as int),
        t1p1: m['t1p1'] as String,
        t1p2: m['t1p2'] as String,
        t2p1: m['t2p1'] as String,
        t2p2: m['t2p2'] as String,
        t1Score: m['t1_score'] as int,
        t2Score: m['t2_score'] as int,
        winningTeam: m['winning_team'] as int,
      );
}
