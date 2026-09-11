import 'dart:async';
import 'dart:ui' show SemanticsAction;
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/match_rules.dart';
import 'package:biliardino/models/rivalry_overview.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/screens/new_match/live_match_view.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';

Finder action(String key) => find.byKey(ValueKey(key));
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<(DesignFixture, NewMatchCubit)> start(
  WidgetTester tester, {
  bool doubles = false,
}) async {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
  addTearDown(tester.view.reset);
  final fixture = DesignFixture();
  await fixture.load();
  await tester.pumpWidget(fixture.home);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.dispose();
  });
  final context = tester.element(find.byType(HomeScreen));
  context.read<HomeCubit>().select(HomeDestination.match);
  final cubit = context.read<NewMatchCubit>();
  cubit.setMatchMode(doubles ? MatchMode.twoVsTwo : MatchMode.oneVsOne);
  cubit.setTeam('p0', 1);
  cubit.setTeam('p3', 2);
  if (doubles) {
    cubit.setTeam('p2', 1);
    cubit.setTeam('p4', 2);
  }
  cubit.kickoff();
  await tester.pumpAndSettle();
  return (fixture, cubit);
}

void main() {
  setUpAll(loadDesignFonts);
  testWidgets(
    '1v1 callbacks, pulse, undo, reset menu, departure and save retry',
    (tester) async {
      final (fixture, cubit) = await start(tester);
      final semantics = tester.ensureSemantics();
      try {
        expect(
          tester.widget<ElevatedButton>(action('live-save-action')).onPressed,
          isNull,
        );
        expect(
          tester
              .getSemantics(action('score-undo-team-1'))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
        );
        await tester.tap(action('score-add-team-1'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 110));
        expect(cubit.state.scorerIds, ['p0']);
        expect(
          tester
              .widget<Transform>(action('score-pulse-1'))
              .transform
              .storage[0],
          greaterThan(1),
        );
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pump();
        expect(
          tester
              .widget<Transform>(action('score-pulse-1'))
              .transform
              .storage[0],
          1,
        );
        await tester.pumpAndSettle();
        await tapVisible(tester, action('score-undo-team-1'));
        expect(cubit.state.score1, 0);
        expect(cubit.state.scorerIds, isEmpty);
        await tapVisible(tester, action('score-add-team-2'));
        await tapVisible(tester, action('live-match-menu'));
        await tapVisible(tester, find.text('Azzera punteggio'));
        await tapVisible(tester, find.text('Annulla'));
        expect(cubit.state.score2, 1);
        await tapVisible(tester, action('live-match-menu'));
        await tapVisible(tester, find.text('Azzera punteggio'));
        await tapVisible(tester, find.text('Azzera'));
        expect(cubit.state.score2, 0);
        await tapVisible(tester, find.byTooltip('Torna alla composizione'));
        await tapVisible(tester, find.text('Annulla'));
        expect(cubit.state.kickedOff, isTrue);
        await tapVisible(tester, action('score-add-team-1'));
        fixture.database.failNextMatchInsert = true;
        await tapVisible(tester, action('live-save-action'));
        expect(
          find.text('Impossibile salvare la partita. Riprova.'),
          findsOneWidget,
        );
        expect(cubit.state.score1, 1);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tapVisible(tester, action('live-save-action'));
        expect(action('victory-overlay'), findsOneWidget);
        await tapVisible(tester, find.text('RIVINCITA'));
        expect(cubit.state.score1, 0);
        await tapVisible(tester, find.byTooltip('Torna alla composizione'));
        await tapVisible(tester, find.text('Abbandona'));
        expect(cubit.state.kickedOff, isFalse);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    '2v2 picker cancels cleanly, attributes second scorer and blocks busy controls',
    (tester) async {
      final (fixture, cubit) = await start(tester, doubles: true);
      await tapVisible(tester, action('score-add-team-1'));
      expect(action('sheet-ribbon-accent'), findsOneWidget);
      await tester.tap(find.byTooltip('Chiudi selezione marcatore'));
      await tester.pumpAndSettle();
      expect(cubit.state.scorerIds, isEmpty);
      await tapVisible(tester, action('score-add-team-1'));
      await tapVisible(tester, find.widgetWithText(ListTile, 'Luca'));
      expect(cubit.state.scorerIds, ['p2']);
      final barrier = Completer<void>();
      fixture.database.matchInsertBarrier = barrier.future;
      await tester.tap(action('live-save-action'));
      await tester.pump();
      expect(cubit.state.isSaving, isTrue);
      expect(
        tester.widget<ElevatedButton>(action('live-save-action')).onPressed,
        isNull,
      );
      final add = find.descendant(
        of: action('score-add-team-2'),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(add).onPressed, isNull);
      barrier.complete();
      await tester.pumpAndSettle();
      expect(action('victory-overlay'), findsOneWidget);
      await tapVisible(tester, find.text('CAMBIA SQUADRE'));
      expect(cubit.state.kickedOff, isFalse);
    },
  );

  for (final (size, scale) in [
    (const Size(440, 956), 1.0),
    (const Size(440, 956), 3.2),
    (const Size(320, 568), 2.0),
    (const Size(568, 320), 2.0),
  ]) {
    testWidgets('Live score and controls reflow at $size / $scale', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final taps = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.southAfrica(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: LiveMatchView(
              rules: const MatchRules(
                mode: MatchRuleMode.firstTo,
                targetScore: 10,
                winByTwo: true,
              ),
              rivalry: const RivalryOverview(
                team1Ids: ['a', 'b'],
                team2Ids: ['c', 'd'],
                totalMatches: 3,
                team1Wins: 2,
                team2Wins: 1,
                team1Goals: 20,
                team2Goals: 15,
              ),
              team1Names: const [
                'Alessandro Antonio Delgaudio',
                'Beatrice Lunghissimo Cognome',
              ],
              team2Names: const [
                'Cristiano Nome Molto Esteso',
                'Daniela Super Competitiva',
              ],
              score1: 99,
              score2: 100,
              isSaving: false,
              awaitingConfirmation: false,
              canRegisterResult: false,
              onAddGoal: taps.add,
              onRemoveGoal: (_) {},
              onSave: () {},
              onBack: () {},
              onReset: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('99'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      for (final team in [1, 2]) {
        for (final prefix in ['score-add-team-', 'score-undo-team-']) {
          final control = action('$prefix$team');
          await tester.ensureVisible(control);
          await tester.pumpAndSettle();
          expect(control.hitTestable(), findsOneWidget);
          expect(
            tester.getSize(control).shortestSide,
            greaterThanOrEqualTo(48),
          );
        }
        await tapVisible(tester, action('score-add-team-$team'));
      }
      expect(taps, [1, 2]);
      await tester.ensureVisible(action('live-save-action'));
      await tester.pumpAndSettle();
      expect(action('live-save-action').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
