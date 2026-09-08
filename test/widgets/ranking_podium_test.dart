import 'package:biliardino/models/player.dart';
import 'package:biliardino/models/player_stats.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/design/ranking_podium.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entrants = [
    for (var i = 0; i < 3; i++)
      PlayerStats(
        player: Player(
          id: 'p$i',
          isPresent: true,
          name: 'Giocatore $i',
          createdAt: DateTime(2026),
        ),
        games: 3,
        wins: 3 - i,
        losses: i,
        goalsScored: 4 - i,
      ),
  ];
  for (var count = 0; count <= 3; count++) {
    testWidgets('Podium with $count entries has only real profile targets', (
      tester,
    ) async {
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.southAfrica(),
          home: Scaffold(
            body: RankingPodium(
              top: entrants.take(count).toList(),
              metricLabel: (s) => '${s.points} pt',
              onOpen: (id) => opened = id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < count; i++) {
        await tester.tap(find.byKey(ValueKey('leaderboard-podium-p$i')));
        expect(opened, 'p$i');
      }
      expect(find.byType(InkWell), findsNWidgets(count));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Podium waits for first visibility and settles on live reduced motion',
    (tester) async {
      var visible = false;
      var reduce = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduce),
                child: TickerMode(
                  enabled: visible,
                  child: Scaffold(
                    body: RankingPodium(
                      top: entrants,
                      metricLabel: (s) => '${s.points} pt',
                      onOpen: (_) {},
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      double offset() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(RankingPodium),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .y;
      await tester.pump(const Duration(seconds: 1));
      expect(offset(), 12);
      update(() => visible = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(offset(), greaterThan(0));
      expect(offset(), lessThan(12));
      update(() => reduce = true);
      await tester.pump();
      expect(offset(), 0);
      update(() {
        visible = false;
        reduce = false;
      });
      await tester.pump();
      update(() => visible = true);
      await tester.pump();
      expect(offset(), 0);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
