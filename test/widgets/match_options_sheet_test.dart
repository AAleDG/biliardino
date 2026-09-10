import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/match_rules.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  final opener = find.byKey(const ValueKey('setup-options-action'));
  final sheet = find.byKey(const ValueKey('match-options-sheet'));
  final close = find.byKey(const ValueKey('close-match-options'));
  final selector = find.byKey(const ValueKey('match-rule-selector'));

  Future<(DesignFixture, NewMatchCubit)> mount(
    WidgetTester tester, {
    Size size = const Size(440, 956),
    double scale = 1,
    bool empty = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final fixture = DesignFixture(empty: empty);
    await fixture.load();
    await tester.pumpWidget(fixture.home);
    final context = tester.element(find.byType(HomeScreen));
    context.read<HomeCubit>().select(HomeDestination.match);
    final cubit = context.read<NewMatchCubit>();
    if (!empty) {
      cubit
        ..setTeam('p0', 1)
        ..setTeam('p2', 1)
        ..setTeam('p3', 2)
        ..setTeam('p4', 2);
    }
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
    return (fixture, cubit);
  }

  Future<void> open(WidgetTester tester) async {
    final scroll = find.descendant(
      of: find.byKey(const ValueKey('setup-scroll-view')),
      matching: find.byType(Scrollable),
    );
    if (opener.evaluate().isEmpty) {
      final position = tester.state<ScrollableState>(scroll).position;
      position.jumpTo(
        position.maxScrollExtent < 240 ? position.maxScrollExtent : 240,
      );
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(opener, 100, scrollable: scroll);
    await Scrollable.ensureVisible(tester.element(opener), alignment: 0);
    await tester.pumpAndSettle();
    await tester.tap(opener);
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
    expect(find.byKey(const ValueKey('sheet-ribbon-accent')), findsOneWidget);
  }

  testWidgets('Live options retain selection, width and underlying layout', (
    tester,
  ) async {
    final (fixture, cubit) = await mount(tester);
    final stage = find.byKey(const ValueKey('setup-team-stage'));
    final stageRect = tester.getRect(stage);
    final summaryRect = tester.getRect(opener);
    await open(tester);
    final selectorRect = tester.getRect(selector);
    await tester.tap(find.text('Primo a N'));
    await tester.pumpAndSettle();
    expect(tester.getRect(selector), selectorRect);
    expect(cubit.state.rules.mode, MatchRuleMode.firstTo);
    await tester.tap(find.byTooltip('Aumenta goal vittoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scarto di 2 goal'));
    await tester.pumpAndSettle();
    expect(cubit.state.rules.targetScore, 11);
    expect(cubit.state.rules.winByTwo, isTrue);
    expect(fixture.rulesRepository.rules, cubit.state.rules);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(find.text('Primo a 11 · Scarto di 2'), findsOneWidget);
    expect(tester.getRect(opener), summaryRect);
    expect(tester.getRect(stage), stageRect);
    await open(tester);
    expect(tester.widget<SegmentedButton<MatchRuleMode>>(selector).selected, {
      MatchRuleMode.firstTo,
    });
    await tester.tap(find.text('Libero'));
    await tester.pumpAndSettle();
    expect(tester.getRect(selector), selectorRect);
    expect(find.text('Goal vittoria'), findsNothing);
    await tester.dragFrom(
      tester.getTopLeft(sheet) + const Offset(200, 22),
      const Offset(0, 700),
    );
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(cubit.state.rules.mode, MatchRuleMode.free);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Both assignment actions dismiss to the resulting teams', (
    tester,
  ) async {
    final (_, cubit) = await mount(tester);
    for (final key in ['random-teams-action', 'balanced-teams-action']) {
      await open(tester);
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(cubit.state.teamsValid, isTrue);
      expect(
        find.byKey(const ValueKey('setup-kickoff-action')).hitTestable(),
        findsOneWidget,
      );
    }
  });

  testWidgets('Assignment actions are disabled for an insufficient roster', (
    tester,
  ) async {
    final (_, cubit) = await mount(tester, empty: true);
    await open(tester);

    expect(cubit.state.present, isEmpty);
    for (final key in ['random-teams-action', 'balanced-teams-action']) {
      expect(
        tester.widget<OutlinedButton>(find.byKey(ValueKey(key))).onPressed,
        isNull,
      );
    }
    expect(sheet, findsOneWidget);
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('Options remain reachable at 200 percent text on $size', (
      tester,
    ) async {
      final (_, cubit) = await mount(tester, size: size, scale: 2);
      await cubit.setRuleMode(MatchRuleMode.firstTo);
      await tester.pumpAndSettle();
      await open(tester);
      final scroll = find.descendant(
        of: find.byKey(const ValueKey('match-options-scroll')),
        matching: find.byType(Scrollable),
      );
      final rivalry = find.text('Modalità Rivalità');
      await tester.scrollUntilVisible(rivalry, 100, scrollable: scroll);
      await tester.ensureVisible(rivalry);
      await tester.pumpAndSettle();
      expect(rivalry.hitTestable(), findsOneWidget);
      expect(close.hitTestable(), findsOneWidget);
      expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
    });
  }
}
