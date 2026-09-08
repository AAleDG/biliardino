import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  testWidgets('Landscape large-text goal announcement remains legible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final fixture = DesignFixture();
    await fixture.load();
    await tester.pumpWidget(
      RepaintBoundary(key: const ValueKey('capture'), child: fixture.home),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
    final context = tester.element(find.byType(HomeScreen));
    context.read<HomeCubit>().selectTab(1);
    final match = context.read<NewMatchCubit>();
    match.setTeam('p0', 1);
    match.setTeam('p2', 1);
    match.setTeam('p3', 2);
    match.setTeam('p4', 2);
    match.kickoff();
    await tester.pumpAndSettle();
    match.addGoal(1, 'p2');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('capture')),
      matchesGoldenFile('south-africa-goal-landscape.png'),
    );
  });
  testWidgets('Live score and goal/victory frames use actual app state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);
    final fixture = DesignFixture();
    await fixture.load();
    await tester.pumpWidget(
      RepaintBoundary(key: const ValueKey('capture'), child: fixture.home),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
    final context = tester.element(find.byType(HomeScreen));
    context.read<HomeCubit>().selectTab(1);
    final match = context.read<NewMatchCubit>();
    match.setTeam('p0', 1);
    match.setTeam('p2', 1);
    match.setTeam('p3', 2);
    match.setTeam('p4', 2);
    match.kickoff();
    for (var i = 0; i < 9; i++) {
      match.addGoal(1, 'p0');
      match.addGoal(2, 'p3');
    }
    match.addGoal(2, 'p4');
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('$name.png'),
      );
    }

    await capture('south-africa-live');
    match.addGoal(1, 'p2');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('goal-overlay')), findsOneWidget);
    await capture('south-africa-goal');
    await tester.pumpAndSettle();
    match.addGoal(2, 'p4');
    await tester.pumpAndSettle();
    await match.save();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await capture('south-africa-victory');
    await tester.tap(find.text('RIVINCITA'));
    await tester.pumpAndSettle();
    expect(match.state.score1, 0);
    expect(match.state.score2, 0);
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await capture('south-africa-live-compact');
    await tester.ensureVisible(find.text('REGISTRA RISULTATO'));
    await tester.pumpAndSettle();
    for (final team in [1, 2]) {
      expect(
        tester.getRect(find.byKey(ValueKey('score-add-team-$team'))).bottom,
        lessThan(470),
      );
    }
    await capture('south-africa-live-compact-controls');
    match.addGoal(2, 'p3');
    await match.save();
    await tester.pumpAndSettle();
    await capture('south-africa-victory-compact');
    await tester.ensureVisible(find.text('CAMBIA SQUADRE'));
    await tester.pumpAndSettle();
    await capture('south-africa-victory-compact-actions');
    await tester.tap(find.text('CAMBIA SQUADRE'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('victory-overlay')), findsNothing);
  });
}
