import 'dart:async';
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/match_rules.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/screens/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../support/design_fixture.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/celebrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Rapid goals coalesce and pending handles dismiss before paint', (
    tester,
  ) async {
    late BuildContext host;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.southAfrica(),
        home: Builder(
          builder: (context) {
            host = context;
            return const Scaffold(body: Text('Background'));
          },
        ),
      ),
    );
    final first = Celebrations.showGoal(
      host,
      color: AppColors.teamOne,
      teamLabel: 'Andrea',
    );
    first.dismiss();
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-overlay')), findsNothing);
    Celebrations.showGoal(host, color: AppColors.teamOne, teamLabel: 'Andrea');
    Celebrations.showGoal(host, color: AppColors.teamTwo, teamLabel: 'Marco');
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-overlay')), findsOneWidget);
    expect(find.text('Marco'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1101));
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-overlay')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Runtime reduced motion preserves goal hold and victory actions work immediately',
    (tester) async {
      late BuildContext host;
      final reduced = ValueNotifier(false);
      addTearDown(reduced.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: reduced,
          builder: (_, value, _) => MaterialApp(
            theme: AppTheme.southAfrica(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: value),
              child: child!,
            ),
            home: Builder(
              builder: (context) {
                host = context;
                return const Scaffold();
              },
            ),
          ),
        ),
      );
      Celebrations.showGoal(
        host,
        color: AppColors.teamOne,
        teamLabel: 'Andrea',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      reduced.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 899));
      expect(find.byKey(const ValueKey('goal-overlay')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
      expect(find.byKey(const ValueKey('goal-overlay')), findsNothing);
      reduced.value = false;
      await tester.pump();
      var rematches = 0;
      Celebrations.showVictory(
        host,
        color: AppColors.teamTwo,
        teamLabel: 'SQUADRA 2',
        playerNames: ['Marco'],
        winnerScore: 10,
        loserScore: 9,
        onChangeTeams: () {},
        onRematch: () => rematches++,
      );
      await tester.pump();
      await tester.tap(find.text('RIVINCITA'));
      await tester.pump();
      expect(rematches, 1);
      expect(find.byKey(const ValueKey('victory-overlay')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Real scoring survives rapid goals, correction, failed save, rematch and disposal',
    (tester) async {
      final fixture = DesignFixture();
      await fixture.load();
      await tester.pumpWidget(fixture.home);
      final context = tester.element(find.byType(HomeScreen));
      final home = context.read<HomeCubit>();
      final match = context.read<NewMatchCubit>();
      home.selectTab(1);
      match.setMatchMode(MatchMode.oneVsOne);
      match.setTeam('p0', 1);
      match.setTeam('p3', 2);
      await match.setRuleMode(MatchRuleMode.firstTo);
      await match.setWinByTwo(true);
      match.kickoff();
      await tester.pump();
      for (var i = 0; i < 9; i++) {
        match.addGoal(1, 'p0');
        match.addGoal(2, 'p3');
      }
      match.addGoal(2, 'p3');
      await tester.pump();
      expect(match.state.scorerIds.length, 19);
      expect(match.state.pendingVictory, isNull);
      expect(find.byKey(const ValueKey('goal-overlay')), findsOneWidget);
      match.removeGoal(2);
      await tester.pump();
      expect(match.state.score2, 9);
      expect(find.byKey(const ValueKey('goal-overlay')), findsNothing);
      match.addGoal(2, 'p3');
      match.addGoal(2, 'p3');
      await tester.pumpAndSettle();
      expect(find.text('Registrare la vittoria?'), findsOneWidget);
      expect(find.byKey(const ValueKey('goal-overlay')), findsNothing);
      await tester.tap(find.text('Correggi'));
      await tester.pumpAndSettle();
      match.removeGoal(2);
      match.addGoal(2, 'p3');
      await tester.pumpAndSettle();
      fixture.database.failNextMatchInsert = true;
      await tester.tap(find.text('Registra'));
      await tester.pumpAndSettle();
      expect(match.state.score2, 11);
      expect(find.text('Registrare la vittoria?'), findsOneWidget);
      expect(find.byKey(const ValueKey('victory-overlay')), findsNothing);
      expect(fixture.database.matches.length, 1);
      await tester.tap(find.text('Registra'));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('victory-overlay')), findsOneWidget);
      expect(fixture.database.matches.length, 2);
      expect(fixture.database.matches.first.scorerIds.length, 20);
      await tester.tap(find.text('RIVINCITA'));
      await tester.pump();
      expect(match.state.score1, 0);
      match.addGoal(1, 'p0');
      await tester.pump();
      home.selectTab(0);
      await tester.pump();
      expect(find.byKey(const ValueKey('goal-overlay')), findsNothing);
      home.selectTab(1);
      match.addGoal(1, 'p0');
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
      await fixture.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Splash settles and hands off once on a runtime accessibility change',
    (tester) async {
      final fixture = DesignFixture();
      await fixture.load();
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(fixture.app);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SplashScreen), findsOneWidget);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Entrance begins next to the approved foot and settles 24px outward',
    (tester) async {
      Future<Rect> ballAt(double progress) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(child: FootOriginEntrance(progress: progress)),
          ),
        );
        return tester.getRect(find.byKey(const ValueKey('splash-football')));
      }

      final start = await ballAt(0);
      final held = await ballAt(.15);
      final finish = await ballAt(1);
      expect(held, start);
      expect(finish.left - start.left, 24);
      final scene = tester.getRect(find.byType(FootOriginEntrance));
      // Rightmost approved foot point (source x=265) at the 2/3 scene scale.
      final footRight = scene.left - 72 + 265 * 2 / 3;
      expect(start.left - footRight, inInclusiveRange(0, 6));
      expect(start.top, lessThan(scene.top + 8 + 219 * 2 / 3));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'A save completed after leaving the match does not open a stale victory',
    (tester) async {
      final fixture = DesignFixture();
      await fixture.load();
      await tester.pumpWidget(fixture.home);
      final context = tester.element(find.byType(HomeScreen));
      final home = context.read<HomeCubit>();
      final match = context.read<NewMatchCubit>();
      home.selectTab(1);
      match.setMatchMode(MatchMode.oneVsOne);
      match.setTeam('p0', 1);
      match.setTeam('p3', 2);
      match.kickoff();
      match.addGoal(1, 'p0');
      await tester.pump();
      final barrier = Completer<void>();
      fixture.database.matchInsertBarrier = barrier.future;
      final saving = match.save();
      await tester.pump();
      expect(match.state.isSaving, isTrue);
      home.selectTab(0);
      await tester.pump();
      barrier.complete();
      await saving;
      await tester.pumpAndSettle();
      expect(fixture.database.matches.length, 2);
      expect(find.byKey(const ValueKey('victory-overlay')), findsNothing);
      expect(find.byKey(const ValueKey('goal-overlay')), findsNothing);
      expect(home.state, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
