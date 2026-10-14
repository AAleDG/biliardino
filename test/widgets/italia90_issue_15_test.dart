import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/presentation/italia90/screens/new_match/match_team_stage.dart';
import 'package:biliardino/presentation/italia90/theme/app_theme.dart';
import 'package:biliardino/presentation/italia90/theme/italia90_tokens.dart';
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

  Future<DesignFixture> mount(
    WidgetTester tester, {
    bool empty = false,
    bool longRoster = false,
    double textScale = 1,
    Size size = const Size(402, 874),
    GlobalKey? boundaryKey,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final fixture = DesignFixture(empty: empty, longRoster: longRoster);
    await fixture.load();
    await fixture.styleRepository.save(AppStyle.italia90);
    await tester.pumpWidget(
      boundaryKey == null
          ? fixture.app
          : RepaintBoundary(key: boundaryKey, child: fixture.app),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
    return fixture;
  }

  void openSetup(WidgetTester tester) {
    final context = tester.element(find.byType(NavigationBar));
    context.read<HomeCubit>().select(HomeDestination.match);
  }

  testWidgets('explains available, occupied and complete team states', (
    tester,
  ) async {
    await mount(tester);
    openSetup(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('setup-team-stage')), findsOneWidget);
    expect(find.text('POSTO DISPONIBILE'), findsNWidgets(4));
    expect(find.text('AGGIUNGI GIOCATORE'), findsNWidgets(2));
    expect(find.text('+1'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('setup-kickoff-action')),
          )
          .onPressed,
      isNull,
    );

    final semantics = tester.ensureSemantics();
    try {
      expect(
        tester.getSemantics(find.byKey(const ValueKey('add-team-1'))),
        matchesSemantics(
          label: 'Aggiungi giocatore alla Squadra 1',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    } finally {
      semantics.dispose();
    }

    final cubit = tester
        .element(find.byType(NavigationBar))
        .read<NewMatchCubit>();
    cubit.setTeam('p0', 1);
    cubit.setTeam('p2', 1);
    cubit.setTeam('p3', 2);
    cubit.setTeam('p4', 2);
    await tester.pumpAndSettle();

    expect(find.text('SQUADRA COMPLETA'), findsNWidgets(2));
    expect(find.text('AGGIUNGI GIOCATORE'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('setup-kickoff-action')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('disabled setup explains why assignment cannot start', (
    tester,
  ) async {
    await mount(tester, empty: true);
    openSetup(tester);
    await tester.pumpAndSettle();

    expect(find.text('IN ATTESA DI GIOCATORI'), findsNWidgets(4));
    expect(find.text('ASSEGNAZIONE DISABILITATA'), findsNWidgets(2));
    expect(find.text('AGGIUNGI GIOCATORE'), findsNWidgets(2));
    expect(
      tester
          .widget<OutlinedButton>(
            find.descendant(
              of: find.byKey(const ValueKey('add-team-1')),
              matching: find.byType(OutlinedButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('setup-kickoff-action')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('large text keeps the stacked teams above the kickoff action', (
    tester,
  ) async {
    await mount(tester, longRoster: true, textScale: 2);
    openSetup(tester);
    await tester.pumpAndSettle();

    final scroll = find.descendant(
      of: find.byKey(const ValueKey('setup-scroll-view')),
      matching: find.byType(Scrollable),
    );
    final teamTwoAdd = find.byKey(const ValueKey('add-team-2'));
    await tester.scrollUntilVisible(teamTwoAdd, 120, scrollable: scroll);
    await Scrollable.ensureVisible(
      tester.element(teamTwoAdd),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();

    final kickoff = tester.getRect(
      find.byKey(const ValueKey('setup-kickoff-action')),
    );
    expect(tester.getRect(teamTwoAdd).bottom, lessThan(kickoff.top));
    expect(kickoff.height, greaterThan(140));
    expect(find.text('INIZIA PARTITA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('300 percent text keeps the assignment flow usable', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();
    await mount(
      tester,
      longRoster: true,
      textScale: 3,
      boundaryKey: boundaryKey,
    );
    openSetup(tester);
    await tester.pumpAndSettle();
    final setupContext = tester.element(find.byType(NavigationBar));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/italia90/backdrop-proposal-2.png'),
        setupContext,
      ),
    );
    await tester.pumpAndSettle();

    final scroll = find.descendant(
      of: find.byKey(const ValueKey('setup-scroll-view')),
      matching: find.byType(Scrollable),
    );
    final teamTwoAdd = find.byKey(const ValueKey('add-team-2'));
    await tester.scrollUntilVisible(teamTwoAdd, 160, scrollable: scroll);
    await Scrollable.ensureVisible(
      tester.element(teamTwoAdd),
      alignment: .15,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();

    final kickoff = tester.getRect(
      find.byKey(const ValueKey('setup-kickoff-action')),
    );
    final kickoffLabel = tester.getRect(find.text('INIZIA PARTITA'));
    expect(tester.getRect(teamTwoAdd).bottom, lessThan(kickoff.top));
    expect(kickoff.height, greaterThan(200));
    expect(kickoffLabel.top, greaterThanOrEqualTo(kickoff.top));
    expect(kickoffLabel.bottom, lessThanOrEqualTo(kickoff.bottom));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        '../goldens/integrated-reference-corrections/flows-setup-300.png',
      ),
    );
  });

  testWidgets('team assignment composition uses the Italia visual language', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final players = [
      Player(
        id: 'p0',
        name: 'Andrea',
        createdAt: DateTime(2026, 9, 1),
        isPresent: true,
      ),
      Player(
        id: 'p2',
        name: 'Luca',
        createdAt: DateTime(2026, 9, 1),
        isPresent: true,
      ),
      Player(
        id: 'p3',
        name: 'Marco',
        createdAt: DateTime(2026, 9, 1),
        isPresent: true,
      ),
      Player(
        id: 'p4',
        name: 'Paolo',
        createdAt: DateTime(2026, 9, 1),
        isPresent: true,
      ),
    ];
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.italia90(),
        home: Scaffold(
          backgroundColor: Italia90.surface,
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: boundaryKey,
              child: MatchTeamStage(
                players: players,
                team1: const ['p0', 'p2'],
                team2: const ['p3', 'p4'],
                capacity: 2,
                enabled: true,
                onAdd: (_) {},
                onEdit: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        '../goldens/integrated-reference-corrections/italia90-team-assignment.png',
      ),
    );
  });
}
