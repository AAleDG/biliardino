import 'dart:ui' show SemanticsAction;

import 'package:biliardino/models/match_rules.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/presentation/italia90/screens/new_match/live_match_view.dart';
import 'package:biliardino/presentation/italia90/theme/app_theme.dart';
import 'package:biliardino/presentation/italia90/theme/italia90_tokens.dart';
import 'package:biliardino/presentation/italia90/widgets/italia90_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('SQUADRA 1'), findsOneWidget);
    expect(find.text('SQUADRA 2'), findsOneWidget);
    expect(find.text('DIVERTITI, GIOCA LEALE, SEMPRE'), findsNothing);
    expect(find.text('PUNTEGGIO LIBERO'), findsNothing);
    expect(find.text('ANNULLA'), findsOneWidget);
    expect(find.text('Andrea'), findsOneWidget);
    expect(find.text('Marco'), findsOneWidget);
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

    final teamTwoHeading = tester.widget<Text>(find.text('SQUADRA 2'));
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
  int score1 = 4,
  int score2 = 5,
  List<String> team1Names = const ['Andrea', 'Luca'],
  List<String> team2Names = const ['Marco', 'Paolo'],
  bool? canRegisterResult,
  bool isSaving = false,
  bool awaitingConfirmation = false,
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
