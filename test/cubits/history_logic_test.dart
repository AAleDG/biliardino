import 'package:biliardino/cubits/history/history_filters.dart';
import 'package:biliardino/cubits/history/history_logic.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/history_design_fixture.dart';

void main() {
  test(
    'history period boundaries include the start day and retain descending date order',
    () {
      final fixture = historyDesignFixture(count: 1);
      addTearDown(fixture.dispose);
      final sample = fixture.database.matches.single;
      final now = DateTime(2026, 9, 12, 15);
      final dates = [
        DateTime(2026, 9, 12),
        DateTime(2026, 9, 6),
        DateTime(2026, 8, 14),
        DateTime(2026, 8, 13, 23, 59),
      ];
      final matches = [
        for (final date in dates.reversed) sample.copyWith(playedAt: date),
      ];
      for (final entry in {
        HistoryPeriod.all: 4,
        HistoryPeriod.today: 1,
        HistoryPeriod.last7Days: 2,
        HistoryPeriod.last30Days: 3,
      }.entries) {
        final actual = filterMatches(
          matches,
          HistoryFilters(period: entry.key),
          now,
        );
        expect(actual.map((m) => m.playedAt), dates.take(entry.value));
      }
    },
  );

  test(
    'rivalry remains distinct from ordinary 1v1 and result filters retain player meaning',
    () {
      final fixture = historyDesignFixture();
      addTearDown(fixture.dispose);
      final matches = fixture.database.matches;
      matches[3] = matches[3].copyWith(isRivalry: true);
      final now = DateTime(2026, 9, 12);
      expect(
        filterMatches(
          matches,
          const HistoryFilters(matchMode: HistoryMatchModeFilter.oneVsOne),
          now,
        ).map((m) => m.id),
        ['history-1'],
      );
      expect(
        filterMatches(
          matches,
          const HistoryFilters(matchMode: HistoryMatchModeFilter.rivalry),
          now,
        ).map((m) => m.id),
        ['history-3'],
      );
      expect(
        filterMatches(
          matches,
          const HistoryFilters(matchMode: HistoryMatchModeFilter.twoVsTwo),
          now,
        ).map((m) => m.id),
        ['history-0', 'history-2'],
      );
      expect(
        filterMatches(
          matches,
          const HistoryFilters(playerId: 'p0', result: HistoryResult.wins),
          now,
        ).map((m) => m.id),
        ['history-2'],
      );
      expect(
        filterMatches(
          matches,
          const HistoryFilters(playerId: 'p0', result: HistoryResult.losses),
          now,
        ).map((m) => m.id),
        ['history-0'],
      );
      final clearedPlayer =
          const HistoryFilters(
            playerId: 'p0',
            result: HistoryResult.wins,
          ).copyWith(
            matchMode: HistoryMatchModeFilter.all,
            period: HistoryPeriod.all,
            playerId: null,
            result: HistoryResult.wins,
          );
      expect(clearedPlayer.result, HistoryResult.all);
      expect(matches.first.mode, MatchMode.twoVsTwo);
    },
  );
}
