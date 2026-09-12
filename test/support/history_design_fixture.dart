import 'package:biliardino/models/game_match.dart';
import 'design_fixture.dart';

/// Synthetic records for History widgets, goldens and the isolated debug review.
/// These never enter the production app's persisted database.
DesignFixture historyDesignFixture({
  int count = 4,
  bool longNames = false,
  bool sameDay = false,
}) {
  final fixture = DesignFixture();
  if (longNames) {
    fixture.database.players[0] = fixture.database.players[0].copyWith(
      name: 'Alessandro Antonio Delgaudio',
    );
    fixture.database.players[2] = fixture.database.players[2].copyWith(
      name: 'Beatrice Lunghissimo Cognome',
    );
  }
  const teams = [
    (['p0', 'p2'], ['p3', 'p4']),
    (['p1'], ['p5']),
    (['p3', 'p5'], ['p0', 'p4']),
    (['p2'], ['p1']),
  ];
  const scores = [(4, 5), (5, 2), (3, 5), (5, 4)];
  final times = [
    DateTime(2026, 1, 7, 13, 30),
    DateTime(2026, 1, 7, 12, 15),
    DateTime(2026, 1, 6, 18, 10),
    DateTime(2026, 1, 6, 17, 30),
  ];
  fixture.database.matches
    ..clear()
    ..addAll(
      List.generate(count, (i) {
        final (left, right) = teams[i % 4];
        final (s1, s2) = longNames && i == 0 ? (10, 12) : scores[i % 4];
        return GameMatch(
          id: 'history-$i',
          playedAt: sameDay
              ? DateTime(2026, 1, 7, 12).add(Duration(minutes: count - i))
              : times[i % 4].subtract(Duration(days: (i ~/ 4) * 2)),
          mode: left.length == 2 ? MatchMode.twoVsTwo : MatchMode.oneVsOne,
          t1p1: left[0],
          t1p2: left.length == 2 ? left[1] : '',
          t2p1: right[0],
          t2p2: right.length == 2 ? right[1] : '',
          t1Score: s1,
          t2Score: s2,
          winningTeam: s1 > s2 ? 1 : 2,
          scorerIds: [
            ...List.filled(s1, left[0]),
            ...List.filled(s2, right[0]),
          ],
        );
      }),
    );
  return fixture;
}
