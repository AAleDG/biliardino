import 'dart:ui' show SemanticsAction;

import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/match_rules.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/presentation/italia90/screens/new_match/live_match_view.dart';
import 'package:biliardino/presentation/italia90/screens/new_match/live_poster_header.dart';
import 'package:biliardino/presentation/italia90/theme/app_theme.dart';
import 'package:biliardino/presentation/italia90/theme/italia90_motion.dart';
import 'package:biliardino/presentation/italia90/theme/italia90_tokens.dart';
import 'package:biliardino/presentation/italia90/widgets/italia90_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

void main() {
  setUpAll(() async {
    for (final item in {
      'Anton': ['assets/fonts/Anton-Regular.ttf'],
      'Italia Barlow': [
        'assets/fonts/Barlow-Regular.ttf',
        'assets/fonts/Barlow-Bold.ttf',
      ],
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
    }.entries) {
      final loader = FontLoader(item.key);
      for (final file in item.value) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    }
  });

  for (final reducedMotion in [false, true]) {
    testWidgets(
      'score replaces the previous value on the first frame with reduced motion $reducedMotion',
      (tester) async {
        final score = ValueNotifier(0);
        addTearDown(score.dispose);
        await tester.pumpWidget(
          Italia90MotionScope(
            reduced: reducedMotion,
            child: MaterialApp(
              home: ValueListenableBuilder<int>(
                valueListenable: score,
                builder: (context, value, child) => Center(
                  child: ItaliaScoreValue(score: value, style: Italia90.score),
                ),
              ),
            ),
          ),
        );
        for (final value in [1, 0, 1, 0]) {
          score.value = value;
          await tester.pump();
          expect(find.text('$value'), findsOneWidget);
          expect(find.text('${1 - value}'), findsNothing);
          expect(
            tester
                .widget<TweenAnimationBuilder<double>>(
                  find.byType(TweenAnimationBuilder<double>),
                )
                .duration,
            reducedMotion ? Duration.zero : Italia90Motion.score,
          );
        }
      },
    );
  }

  for (final mode in MatchMode.values) {
    for (final team in [1, 2]) {
      testWidgets(
        'first goal undo is immediate across the button for ${mode.dbValue} team $team',
        (tester) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final fixture = DesignFixture();
          await fixture.load();
          await fixture.styleRepository.save(AppStyle.italia90);
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox.shrink());
            await fixture.dispose();
          });
          await tester.pumpWidget(fixture.app);
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(NavigationBar));
          final cubit = context.read<NewMatchCubit>();
          cubit.setMatchMode(mode);
          cubit.setTeam('p0', 1);
          cubit.setTeam('p3', 2);
          if (mode == MatchMode.twoVsTwo) {
            cubit.setTeam('p2', 1);
            cubit.setTeam('p4', 2);
          }
          context.read<HomeCubit>().select(HomeDestination.match);
          cubit.kickoff();
          await tester.pumpAndSettle();
          final goal = find.byKey(ValueKey('score-add-team-$team'));
          await tester.ensureVisible(goal);
          await tester.pumpAndSettle();

          for (var attempt = 0; attempt < 3; attempt++) {
            await tester.tap(goal);
            await tester.pump();
            expect(cubit.state.score1 + cubit.state.score2, 1);
            expect(find.text('1'), findsOneWidget);
            final undo = find.byKey(ValueKey('score-undo-team-$team'));
            final bounds = tester.getRect(undo);
            // Tap the opposite side from the scoring team's former half.
            await tester.tapAt(
              team == 1
                  ? bounds.centerRight - const Offset(8, 0)
                  : bounds.centerLeft + const Offset(8, 0),
            );
            await tester.pump();

            expect(cubit.state.score1, 0);
            expect(cubit.state.score2, 0);
            expect(cubit.state.scorerIds, isEmpty);
            expect(find.text('1'), findsNothing);
            expect(find.text('0'), findsNWidgets(2));
            expect(find.byKey(const ValueKey('goal-overlay')), findsNothing);
            expect(
              tester
                  .widget<ElevatedButton>(
                    find.byKey(const ValueKey('live-save-action')),
                  )
                  .onPressed,
              isNull,
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('uses one live panel per team with accessible team context', (
    tester,
  ) async {
    final addedGoals = <String>[];
    final removedTeams = <int>[];
    await _pumpLiveMatch(
      tester,
      score1: 4,
      score2: 5,
      onAddGoal: (team, playerId) => addedGoals.add('$team:$playerId'),
      onRemoveGoal: removedTeams.add,
    );

    expect(find.byType(ItaliaScoreboard), findsOneWidget);
    expect(find.byType(TeamScorePanel), findsNWidgets(2));
    expect(find.byKey(const ValueKey('live-team-panel-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('live-team-panel-2')), findsOneWidget);
    expect(find.text('SQUADRA 1'), findsNWidgets(2));
    expect(find.text('SQUADRA 2'), findsNWidgets(2));
    expect(find.text('DIVERTITI, GIOCA LEALE, SEMPRE'), findsNothing);
    expect(find.text('PUNTEGGIO LIBERO'), findsNothing);
    expect(find.text('ANNULLA'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('score-undo-team-1')),
        matching: find.text('SQUADRA 1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('score-undo-team-2')),
        matching: find.text('SQUADRA 2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('live-team-panel-1')),
        matching: find.text('Andrea'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('live-team-panel-2')),
        matching: find.text('Marco'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('live-team-panel-1')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('live-team-panel-2')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );

    final teamTwoGoal = find.byKey(const ValueKey('score-add-team-2'));
    await tester.ensureVisible(teamTwoGoal);
    await tester.pumpAndSettle();

    final semantics = tester.ensureSemantics();
    try {
      expect(
        tester.getSemantics(find.byKey(const ValueKey('score-team-2'))),
        matchesSemantics(label: 'Punteggio SQUADRA 2: 5', isLiveRegion: true),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('score-add-team-2'))),
        matchesSemantics(
          label: 'Aggiungi un goal a Marco per SQUADRA 2. Punteggio attuale 5.',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    } finally {
      semantics.dispose();
    }

    final teamTwoHeading = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('live-team-panel-2')),
        matching: find.text('SQUADRA 2'),
      ),
    );
    expect(teamTwoHeading.style?.color, Italia90.ink);
    expect(
      _contrastRatio(Italia90.ink, Italia90.teamTwo),
      greaterThanOrEqualTo(4.5),
    );

    await tester.tap(find.byKey(const ValueKey('score-add-team-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('score-undo-team-1')));
    await tester.pump();
    expect(addedGoals, ['2:team2-0']);
    expect(removedTeams, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the 0–0 result action disabled', (tester) async {
    await _pumpLiveMatch(tester, score1: 0, score2: 0);

    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('live-save-action')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('score-undo-team-1')))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('score-add-team-1')))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the saving label readable at large text', (tester) async {
    await _pumpLiveMatch(
      tester,
      size: const Size(320, 568),
      textScale: 2,
      isSaving: true,
      canRegisterResult: false,
    );

    expect(find.text('SALVATAGGIO...'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('live-save-action'))).height,
      greaterThan(64),
    );
    expect(tester.getSize(find.text('SALVATAGGIO...')).height, greaterThan(45));
    expect(tester.takeException(), isNull);
  });

  testWidgets('grows split undo controls at very large text', (tester) async {
    await _pumpLiveMatch(
      tester,
      size: const Size(320, 568),
      textScale: 3,
      score1: 1,
      score2: 2,
      canRegisterResult: false,
    );

    expect(
      tester.getSize(find.byType(ItaliaSharedUndoAction)).height,
      greaterThan(64),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('score-undo-team-1'))).height,
      greaterThan(64),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('score-undo-team-2'))).height,
      greaterThan(64),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grows a single undo control at very large text', (tester) async {
    await _pumpLiveMatch(
      tester,
      size: const Size(320, 568),
      textScale: 3,
      score1: 0,
      score2: 2,
      canRegisterResult: false,
    );

    expect(
      tester.getSize(find.byType(ItaliaSharedUndoAction)).height,
      greaterThan(64),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('score-undo-team-2'))).height,
      greaterThan(64),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders live poster scores from the current match state', (
    tester,
  ) async {
    await _pumpLiveMatch(
      tester,
      score1: 0,
      score2: 0,
      showInteractivePanel: false,
    );

    expect(find.byType(ItaliaScoreboard), findsNothing);
    expect(find.text('0'), findsNWidgets(2));
    final backButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const ValueKey('new-match-back')),
        matching: find.byType(IconButton),
      ),
    );
    expect(backButton.color, Italia90.ink);
    expect(
      backButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      Colors.transparent,
    );

    final semantics = tester.ensureSemantics();
    try {
      expect(
        tester.getSemantics(find.text('0').first),
        matchesSemantics(label: 'Punteggio SQUADRA 1: 0', isLiveRegion: true),
      );
    } finally {
      semantics.dispose();
    }

    await _pumpLiveMatch(
      tester,
      score1: 1,
      score2: 2,
      showInteractivePanel: false,
    );
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('centres one real player per team without covering actions', (
    tester,
  ) async {
    final goals = <String>[];
    await _pumpLiveMatch(
      tester,
      mode: MatchMode.oneVsOne,
      team1Names: const ['Alex', 'Luca'],
      team2Names: const ['Maruzzo', 'Marco'],
      onAddGoal: (team, id) => goals.add('$team:$id'),
      showInteractivePanel: false,
    );

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Maruzzo'), findsOneWidget);
    expect(find.text('Luca'), findsNothing);
    expect(find.text('Marco'), findsNothing);
    expect(find.text('+1 GOAL'), findsNWidgets(2));
    expect(find.text('ANNULLA'), findsNWidgets(2));
    expect(find.text('REGISTRA RISULTATO'), findsOneWidget);
    for (final (team, name) in [(1, 'Alex'), (2, 'Maruzzo')]) {
      final roster = find.byKey(ValueKey('live-roster-team-$team'));
      expect(
        tester.getCenter(find.text(name)).dx,
        closeTo(tester.getCenter(roster).dx, 0.01),
      );
      final goal = find.byKey(ValueKey('score-add-team-$team'));
      await tester.ensureVisible(goal);
      await tester.pumpAndSettle();
      expect(tester.getSize(goal).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(goal);
      await tester.pump();
    }
    expect(goals, ['1:team1-0', '2:team2-0']);
    final save = find.byKey(const ValueKey('live-save-action'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(save.hitTestable(), findsOneWidget);
    expect(
      tester.getRect(save).overlaps(tester.getRect(find.text('Maruzzo'))),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps four live players and goal actions in 2v2', (
    tester,
  ) async {
    await _pumpLiveMatch(tester, showInteractivePanel: false);
    for (final name in ['Andrea', 'Luca', 'Marco', 'Paolo']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('+1 GOAL'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('1v1 layout golden with Alex and Maruzzo', (tester) async {
    await _pumpLiveMatch(
      tester,
      mode: MatchMode.oneVsOne,
      showInteractivePanel: false,
      team1Names: const ['Alex'],
      team2Names: const ['Maruzzo'],
      score1: 0,
      score2: 0,
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/italia90/live-poster-editoriale.png'),
        tester.element(find.byType(LiveMatchView)),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../goldens/integrated-reference-corrections/live-1v1.png',
      ),
    );
  });

  testWidgets('1v1 layout golden with enabled result action', (tester) async {
    await _pumpLiveMatch(
      tester,
      mode: MatchMode.oneVsOne,
      showInteractivePanel: false,
      team1Names: const ['Alex'],
      team2Names: const ['Maruzzo'],
      score1: 2,
      score2: 0,
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/italia90/live-poster-editoriale.png'),
        tester.element(find.byType(LiveMatchView)),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../goldens/integrated-reference-corrections/live-1v1-2-0.png',
      ),
    );
  });

  testWidgets('poster disables real goal and result controls during save', (
    tester,
  ) async {
    await _pumpLiveMatch(
      tester,
      mode: MatchMode.oneVsOne,
      showInteractivePanel: false,
      isSaving: true,
      canRegisterResult: false,
    );
    expect(find.text('SALVATAGGIO...'), findsOneWidget);
    for (final team in [1, 2]) {
      expect(
        tester
            .getSemantics(find.byKey(ValueKey('score-add-team-$team')))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
    }
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('live-save-action')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('1v1 poster uses readable scrolling content at large text', (
    tester,
  ) async {
    await _pumpLiveMatch(
      tester,
      mode: MatchMode.oneVsOne,
      showInteractivePanel: false,
      size: const Size(320, 568),
      textScale: 2,
      team1Names: const ['Alessandro Antonio Delgaudio'],
      team2Names: const ['Maruzzo Cognome Molto Lungo'],
    );
    for (final key in [
      'score-add-team-1',
      'score-add-team-2',
      'score-undo-team-1',
      'score-undo-team-2',
      'live-save-action',
    ]) {
      final action = find.byKey(ValueKey(key));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.getSize(action).shortestSide, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the back arrow fixed while the poster scrolls', (
    tester,
  ) async {
    await _pumpLiveMatch(
      tester,
      size: const Size(402, 640),
      showInteractivePanel: false,
    );

    final backButton = find.byKey(const ValueKey('new-match-back'));
    final posterImage = find.byType(Image).first;
    final backBefore = tester.getTopLeft(backButton);
    final posterBefore = tester.getTopLeft(posterImage);

    await tester.drag(
      find.byKey(const ValueKey('live-match-scroll')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(backButton), backBefore);
    expect(tester.getTopLeft(posterImage).dy, lessThan(posterBefore.dy));
  });

  testWidgets('removes the secondary navigation strip from the live poster', (
    tester,
  ) async {
    await _pumpLiveMatch(
      tester,
      showInteractivePanel: false,
      size: const Size(402, 874),
    );

    expect(
      tester.getSize(find.byType(LivePosterHeader)).height,
      closeTo(
        402 *
            LivePosterHeader.visibleArtworkHeight /
            LivePosterHeader.sourceWidth,
        0.01,
      ),
    );
  });

  testWidgets('keeps score controls and save disabled while saving', (
    tester,
  ) async {
    await _pumpLiveMatch(tester, isSaving: true, canRegisterResult: false);

    expect(find.text('SALVATAGGIO...'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('live-save-action')),
          )
          .onPressed,
      isNull,
    );
    for (final team in [1, 2]) {
      for (final prefix in ['score-add-team-', 'score-undo-team-']) {
        expect(
          tester
              .getSemantics(find.byKey(ValueKey('$prefix$team')))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('stacks two-digit scores and long names at large text', (
    tester,
  ) async {
    await _pumpLiveMatch(
      tester,
      size: const Size(320, 568),
      textScale: 2,
      score1: 99,
      score2: 100,
      team1Names: const ['Alessandro Antonio Delgaudio'],
      team2Names: const ['Beatrice Lunghissimo Cognome'],
      canRegisterResult: false,
    );

    expect(find.text('99'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('live-save-action'))).height,
      greaterThan(64),
    );
    expect(
      tester.getSize(find.text('REGISTRA RISULTATO')).height,
      greaterThan(45),
    );
    expect(find.byKey(const ValueKey('live-match-scroll')), findsOneWidget);
    for (final team in [1, 2]) {
      for (final prefix in ['score-add-team-', 'score-undo-team-']) {
        final control = find.byKey(ValueKey('$prefix$team'));
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        expect(control.hitTestable(), findsOneWidget);
        expect(tester.getSize(control).shortestSide, greaterThanOrEqualTo(48));
      }
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLiveMatch(
  WidgetTester tester, {
  Size size = const Size(402, 874),
  double textScale = 1,
  MatchMode mode = MatchMode.twoVsTwo,
  int score1 = 4,
  int score2 = 5,
  List<String> team1Names = const ['Andrea', 'Luca'],
  List<String> team2Names = const ['Marco', 'Paolo'],
  bool? canRegisterResult,
  bool isSaving = false,
  bool awaitingConfirmation = false,
  bool showInteractivePanel = true,
  void Function(int team, String playerId)? onAddGoal,
  ValueChanged<int>? onRemoveGoal,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.italia90(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: LiveMatchView(
          mode: mode,
          rules: const MatchRules(
            mode: MatchRuleMode.free,
            targetScore: 10,
            winByTwo: false,
          ),
          rivalry: null,
          team1Players: _testPlayers('team1', team1Names),
          team2Players: _testPlayers('team2', team2Names),
          score1: score1,
          score2: score2,
          isSaving: isSaving,
          awaitingConfirmation: awaitingConfirmation,
          canRegisterResult:
              canRegisterResult ?? (score1 != score2 && score1 + score2 > 0),
          onAddGoal: onAddGoal ?? (_, _) {},
          onRemoveGoal: onRemoveGoal ?? (_) {},
          onSave: () {},
          onBack: () {},
          onReset: () {},
          showInteractivePanel: showInteractivePanel,
        ),
      ),
    ),
  );
  if (isSaving) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}

List<Player> _testPlayers(String team, List<String> names) => [
  for (var index = 0; index < names.length; index++)
    Player(
      id: '$team-$index',
      name: names[index],
      createdAt: DateTime(2020),
      isPresent: true,
    ),
];

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
