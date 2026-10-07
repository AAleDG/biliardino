import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/navigation/app_navigation.dart';
import 'package:biliardino/screens/leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../support/design_fixture.dart';
import '../support/leaderboard_fixture.dart';

void main() {
  setUpAll(() async {
    await loadDesignFonts();
    await initializeDateFormatting('it_IT');
  });
  for (final compact in [false, true]) {
    testWidgets(
      'approved pair profile ${compact ? 'compact large text' : 'normal'}',
      (tester) async {
        tester.view.physicalSize = compact
            ? const Size(320, 568)
            : const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = compact ? 2 : 1;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixture = LeaderboardFixture(
          count: 2,
          mode: MatchMode.twoVsTwo,
          longNames: compact,
        );
        await tester.runAsync(fixture.load);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(fixture.dispose);
        });
        await tester.pumpWidget(
          RepaintBoundary(key: const ValueKey('capture'), child: fixture.app()),
        );
        await tester.pumpAndSettle();
        openPairProfile(
          tester.element(find.byType(LeaderboardScreen)),
          fixture.cubit.state.teamGeneral.first.id,
        );
        await tester.pumpAndSettle();
        final suffix = compact ? 'compact' : 'normal';
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile('pair-profile-$suffix-top.png'),
        );
        await tester.drag(
          find.byType(Scrollable).last,
          const Offset(0, -10000),
        );
        await tester.pumpAndSettle();
        expect(find.text('Vittoria · 2-1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile('pair-profile-$suffix-bottom.png'),
        );
      },
    );
  }
}
