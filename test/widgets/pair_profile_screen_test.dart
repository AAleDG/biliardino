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
  testWidgets(
    'long pair profile reflows at 200% and keeps complete history reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = LeaderboardFixture(
        count: 2,
        mode: MatchMode.twoVsTwo,
        longNames: true,
      );
      await tester.runAsync(fixture.load);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(fixture.dispose);
      });
      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      openPairProfile(
        tester.element(find.byType(LeaderboardScreen)),
        fixture.cubit.state.teamGeneral.first.id,
      );
      await tester.pumpAndSettle();
      for (final member in fixture.cubit.state.teamGeneral.first.players) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('pair-member-${member.id}')),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(
          find.byKey(ValueKey('pair-member-${member.id}')),
          findsOneWidget,
        );
      }
      await tester.scrollUntilVisible(
        find.text('Vittoria · 2-1'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Vittoria · 2-1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing pair has a readable unavailable state and can return to rankings',
    (tester) async {
      final fixture = LeaderboardFixture();
      await tester.runAsync(fixture.load);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(fixture.dispose);
      });
      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      openPairProfile(
        tester.element(find.byType(LeaderboardScreen)),
        'missing',
      );
      await tester.pumpAndSettle();
      expect(find.text('Coppia non trovata.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
