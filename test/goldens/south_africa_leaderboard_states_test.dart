import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';
import '../support/leaderboard_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  for (final count in [0, 1, 2, 3]) {
    testWidgets('Classifica sparse $count with safe areas and real fonts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 54, bottom: 34);
      addTearDown(tester.view.reset);
      final fixture = LeaderboardFixture(count: count);
      await tester.runAsync(fixture.load);
      await tester.pumpWidget(
        RepaintBoundary(key: const ValueKey('capture'), child: fixture.app()),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(fixture.dispose);
      });
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(
            'design/south-africa-2010/assets/live-r1/live-scene.png',
          ),
          tester.element(find.byType(Scaffold).first),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('leaderboard-$count.png'),
      );
    });
  }
  for (final size in [
    const Size(402, 874),
    const Size(320, 568),
    const Size(568, 320),
  ]) {
    testWidgets('Classifica long names and final row at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = size.width == 402
          ? 1
          : 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = LeaderboardFixture(count: 20, longNames: true);
      await tester.runAsync(fixture.load);
      await tester.pumpWidget(
        RepaintBoundary(key: const ValueKey('capture'), child: fixture.app()),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(fixture.dispose);
      });
      for (final tab in ['Generale', 'Marcatori']) {
        if (tab == 'Marcatori' && size.height < 450) {
          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, 10000),
          );
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(
          find
              .ancestor(of: find.text(tab), matching: find.byType(InkWell))
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final mode = tab == 'Generale' ? 'general' : 'scorers';
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile(
            'leaderboard-long-$mode-${size.width.toInt()}-top.png',
          ),
        );
        final last =
            (tab == 'Generale'
                    ? fixture.cubit.state.general
                    : fixture.cubit.state.scorers)
                .last;
        final target = find.byKey(
          ValueKey('leaderboard-row-${last.player.id}'),
        );
        await tester.scrollUntilVisible(
          target,
          220,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        // The very tall final card may exceed a landscape viewport; its ending must remain reachable.
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(target).bottom,
          lessThanOrEqualTo(size.height - 24),
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile(
            'leaderboard-long-$mode-${size.width.toInt()}-bottom.png',
          ),
        );
      }
    });
  }
}
