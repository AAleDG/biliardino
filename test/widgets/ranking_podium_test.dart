import 'package:biliardino/models/player.dart';
import 'package:biliardino/models/player_badge.dart';
import '../support/design_fixture.dart';
import 'package:biliardino/models/player_stats.dart';
import 'package:biliardino/models/ranking_stats.dart';
import 'package:biliardino/models/team_leaderboard_stats.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/design/ranking_podium.dart';
import 'package:biliardino/widgets/design/ranking_award_ticket.dart';
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
  for (final pair in [false, true]) {
    for (final longMetric in [false, true]) {
      testWidgets(
        '${pair ? 'pair' : 'individual'} achievements retain artwork with ordinary scores and fallback with long scores ($longMetric)',
        (tester) async {
          await loadDesignFonts();
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          const awards = [
            ('leader', 'Capoclassifica'),
            ('bomber', 'Bomber'),
            ('grinder', 'Presenza Fissa'),
            ('dominant', 'Implacabile'),
            ('streak', 'Hot Streak'),
            ('rivalry', 'Re delle Rivalità'),
          ];
          final badges = [
            for (final award in pair ? awards.take(3) : awards)
              PlayerBadge(
                code: award.$1,
                label: award.$2,
                description: 'Descrizione di ${award.$2}',
              ),
          ];
          final alex = entrants.first.player.copyWith(name: 'Alex');
          final RankingStats stats = pair
              ? TeamLeaderboardStats(
                  id: 'pair',
                  players: [
                    alex,
                    entrants[1].player.copyWith(name: 'Luca'),
                  ],
                  games: 3,
                  wins: 3,
                  losses: 0,
                  goalsScored: 4,
                  badges: badges,
                )
              : PlayerStats(
                  player: alex,
                  games: 4,
                  wins: 3,
                  losses: 1,
                  goalsScored: 4,
                  badges: badges,
                );
          String? opened;
          Widget podiumApp(RankingStats entry) => MaterialApp(
            theme: AppTheme.southAfrica(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: RankingPodium(
                  top: [entry],
                  metricLabel: (_) =>
                      longMetric ? '12345678901234567890 pt' : '9 pt',
                  onOpen: (id) => opened = id,
                ),
              ),
            ),
          );
          await tester.pumpWidget(podiumApp(stats));
          final ctx = tester.element(find.byType(Scaffold));
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(
                'design/south-africa-2010/assets/live-r1/live-scene.png',
              ),
              ctx,
            ),
          );
          await tester.pumpAndSettle();
          final pedestal = find.byKey(const ValueKey('podium-block-1'));
          expect(pedestal, longMetric ? findsNothing : findsOneWidget);
          for (final badge in badges) {
            expect(find.text(badge.label), findsOneWidget);
          }
          if (!longMetric) {
            for (final badge in badges.skip(2)) {
              expect(find.text(badge.description), findsOneWidget);
            }
            expect(
              tester.getTopLeft(find.text('Presenza Fissa')).dy,
              greaterThan(tester.getBottomRight(pedestal).dy),
              reason:
                  'Additional achievements stay below the illustrated podium',
            );
            await expectLater(
              find.byType(Scaffold),
              matchesGoldenFile(
                '../goldens/podium-extra-awards-${pair ? 'pairs' : 'singles'}.png',
              ),
            );
          }
          if (!longMetric) {
            tester.platformDispatcher.textScaleFactorTestValue = 2;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await tester.pumpAndSettle();
            expect(pedestal, findsNothing);
            for (final badge in badges) {
              expect(find.text(badge.label), findsOneWidget);
            }
            await tester.ensureVisible(
              find.byKey(ValueKey('leaderboard-podium-${stats.id}')),
            );
          }
          await tester.tap(
            find.byKey(ValueKey('leaderboard-podium-${stats.id}')),
          );
          expect(opened, stats.id);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final textScale in [1.0, 2.0]) {
    testWidgets(
      'pair award ticket is readable at narrow width and $textScale text',
      (tester) async {
        await loadDesignFonts();
        tester.view.physicalSize = const Size(343, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        const badge = PlayerBadge(
          code: 'grinder',
          label: 'Presenza Fissa',
          description: 'È la coppia più presente nelle partite 2vs2.',
        );
        final stats = TeamLeaderboardStats(
          id: 'pair',
          players: [
            entrants[0].player.copyWith(name: 'A'),
            entrants[1].player.copyWith(name: 'B'),
          ],
          games: 3,
          wins: 3,
          losses: 0,
          goalsScored: 4,
          badges: const [badge],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.southAfrica(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: RankingAwardTicket(stats: stats, badges: stats.badges),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('A + B'), findsOneWidget);
        expect(find.text(badge.label), findsOneWidget);
        await tester.ensureVisible(find.text(badge.description));
        expect(tester.takeException(), isNull);
        expect(
          tester.getBottomRight(find.text(badge.description)).dy,
          lessThanOrEqualTo(568),
        );
      },
    );
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
