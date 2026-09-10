import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';

void main() {
  Future<DesignFixture> mount(
    WidgetTester tester, {
    bool empty = false,
    bool longRoster = false,
    Size size = const Size(402, 874),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final fixture = DesignFixture(empty: empty, longRoster: longRoster);
    await fixture.load();
    await tester.pumpWidget(fixture.home);
    tester
        .element(find.byType(HomeScreen))
        .read<HomeCubit>()
        .select(HomeDestination.players);
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
    return fixture;
  }

  testWidgets('Presence and overflow actions remain independent of profile', (
    tester,
  ) async {
    final fixture = await mount(tester, scale: 2, longRoster: true);
    final presence = find.byKey(const ValueKey('player-presence-p0'));
    await tester.ensureVisible(presence);
    await tester.tap(presence);
    await tester.pumpAndSettle();
    expect(
      fixture.database.players.firstWhere((p) => p.id == 'p0').isPresent,
      isFalse,
    );
    expect(find.text('GIOCATORI'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('player-actions-p0')));
    await tester.pumpAndSettle();
    expect(find.text('Modifica nome'), findsOneWidget);
    expect(fixture.database.updatePlayerCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Full roster and team picker remain operable above kickoff at 200 percent',
    (tester) async {
      await mount(tester, scale: 2, longRoster: true);
      final context = tester.element(find.byType(HomeScreen));
      context.read<HomeCubit>().select(HomeDestination.match);
      await tester.pumpAndSettle();
      final setupScroll = find.descendant(
        of: find.byKey(const ValueKey('setup-scroll-view')),
        matching: find.byType(Scrollable),
      );
      final showAll = find.text('VEDI TUTTI (8)');
      await tester.scrollUntilVisible(showAll, 160, scrollable: setupScroll);
      await Scrollable.ensureVisible(
        tester.element(showAll),
        alignment: .5,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(showAll);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('present-player-p7')), findsNothing);
      final lastRosterPlayer = find.byKey(
        const ValueKey('roster-sheet-player-p7'),
      );
      final sheetScroll = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        lastRosterPlayer,
        120,
        scrollable: sheetScroll,
      );
      expect(find.text('Beatrice Lunghissimo Cognome'), findsOneWidget);
      Navigator.of(tester.element(lastRosterPlayer)).pop();
      await tester.pumpAndSettle();

      final add = find.byKey(const ValueKey('add-team-2'));
      await tester.scrollUntilVisible(add, 160, scrollable: setupScroll);
      await Scrollable.ensureVisible(
        tester.element(add),
        alignment: .4,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      final chip = find.byKey(const ValueKey('team-chip-p7-team-2'));
      final teamSheetScroll = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(chip, 120, scrollable: teamSheetScroll);
      await Scrollable.ensureVisible(
        tester.element(chip),
        alignment: .5,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(context.read<NewMatchCubit>().state.team2, contains('p7'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Empty setup can scroll to all guidance in compact landscape', (
    tester,
  ) async {
    await mount(tester, empty: true, scale: 2, size: const Size(568, 320));
    tester
        .element(find.byType(HomeScreen))
        .read<HomeCubit>()
        .select(HomeDestination.match);
    await tester.pumpAndSettle();
    final setupScroll = find.descendant(
      of: find.byKey(const ValueKey('setup-scroll-view')),
      matching: find.byType(Scrollable),
    );
    final guidance = find.text('Vai su Giocatori e segna chi è presente.');
    await tester.scrollUntilVisible(guidance, 120, scrollable: setupScroll);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(guidance).bottom, lessThan(320));
  });
}
