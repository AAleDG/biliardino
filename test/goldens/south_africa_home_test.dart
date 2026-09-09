import 'package:biliardino/screens/dashboard_screen.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);

  for (final scenario in const [
    (name: 'home', size: Size(402, 874), scale: 1.0),
    (name: 'home-compact', size: Size(320, 568), scale: 2.0),
    (name: 'home-landscape', size: Size(568, 320), scale: 2.0),
  ]) {
    testWidgets('${scenario.name} uses real fonts and the approved hero', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(
        top: scenario.size.height > 400 ? 62 : 20,
        bottom: scenario.size.height > 400 ? 34 : 0,
      );
      tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final fixture = DesignFixture(populatedDashboard: true);
      await fixture.load();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('home-capture'),
          child: fixture.home,
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(homeHeroAssetPath),
          tester.element(find.byType(DashboardScreen)),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await fixture.dispose();
      });

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('home-capture')),
        matchesGoldenFile('south-africa-${scenario.name}.png'),
      );
      await tester.drag(
        find.byKey(const PageStorageKey('dashboard-scroll')),
        const Offset(0, -1200),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('home-capture')),
        matchesGoldenFile('south-africa-${scenario.name}-content.png'),
      );
    });
  }

  testWidgets('empty Home uses real fonts and explicit section states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    final fixture = DesignFixture(empty: true);
    await fixture.load();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('empty-home-capture'),
        child: fixture.home,
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(homeHeroAssetPath),
        tester.element(find.byType(DashboardScreen)),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });

    await expectLater(
      find.byKey(const ValueKey('empty-home-capture')),
      matchesGoldenFile('south-africa-home-empty.png'),
    );
    await tester.drag(
      find.byKey(const PageStorageKey('dashboard-scroll')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('empty-home-capture')),
      matchesGoldenFile('south-africa-home-empty-content.png'),
    );
  });
}
