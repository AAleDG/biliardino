import 'package:biliardino/navigation/app_navigation.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';
import '../support/history_design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  for (final scene in [
    ('reference', const Size(402, 874), 1.0, 4, false),
    ('sparse', const Size(402, 874), 1.0, 1, false),
    ('compact', const Size(320, 568), 2.0, 1, true),
    ('landscape', const Size(568, 320), 2.0, 1, true),
  ]) {
    testWidgets('Tabellone real fonts ${scene.$1}', (tester) async {
      tester.view.physicalSize = scene.$2;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = scene.$1 == 'landscape'
          ? const FakeViewPadding(left: 44, right: 44, bottom: 24)
          : const FakeViewPadding(top: 62, bottom: 34);
      tester.platformDispatcher.textScaleFactorTestValue = scene.$3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = historyDesignFixture(
        count: scene.$4,
        longNames: scene.$5,
      );
      await fixture.load();
      await tester.pumpWidget(
        RepaintBoundary(key: const ValueKey('capture'), child: fixture.home),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await fixture.dispose();
      });
      await tester.pumpAndSettle();
      openHistory(tester.element(find.byType(HomeScreen)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('south-africa-history-tabellone-${scene.$1}.png'),
      );
      if (scene.$5) {
        final scrollable = find.descendant(
          of: find.byKey(const ValueKey('history-scroll')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text('12'),
          150,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile(
            'south-africa-history-tabellone-${scene.$1}-scrolled.png',
          ),
        );
      }
    });
  }
}
