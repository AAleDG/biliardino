import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/presentation/italia90/theme/app_theme.dart';
import 'package:biliardino/presentation/italia90/theme/design_tokens.dart';
import 'package:biliardino/presentation/italia90/screens/new_match/match_setup_roster.dart';
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
    required Size size,
    required double textScale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final fixture = DesignFixture();
    await fixture.load();
    await fixture.styleRepository.save(AppStyle.italia90);
    await tester.pumpWidget(fixture.app);
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
    return fixture;
  }

  void openSetup(WidgetTester tester) {
    tester
        .element(find.byType(NavigationBar))
        .read<HomeCubit>()
        .select(HomeDestination.match);
  }

  Finder setupScroll() => find.descendant(
    of: find.byKey(const ValueKey('setup-scroll-view')),
    matching: find.byType(Scrollable),
  );

  testWidgets('keeps team-2 setup status text readable', (tester) async {
    await mount(tester, size: const Size(402, 874), textScale: 1);
    openSetup(tester);
    await tester.pumpAndSettle();

    final available = find.text('POSTO DISPONIBILE');
    expect(available, findsNWidgets(4));
    final kickoff = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('setup-kickoff-action')),
    );
    expect(
      kickoff.style?.backgroundColor?.resolve(const <WidgetState>{}),
      AppColors.homeAction,
    );
    final availableTeamTwo = find.descendant(
      of: find.byKey(const ValueKey('team-2-empty-0')),
      matching: find.text('POSTO DISPONIBILE'),
    );
    expect(availableTeamTwo, findsOneWidget);
    expect(tester.widget<Text>(availableTeamTwo).style?.color, AppColors.ink);

    final context = tester.element(find.byType(NavigationBar));
    final cubit = context.read<NewMatchCubit>();
    cubit.setTeam('p0', 1);
    cubit.setTeam('p2', 1);
    cubit.setTeam('p3', 2);
    cubit.setTeam('p4', 2);
    await tester.pumpAndSettle();

    final completeTeamTwo = find.descendant(
      of: find.byKey(const ValueKey('team-2-complete')),
      matching: find.text('SQUADRA COMPLETA'),
    );
    expect(completeTeamTwo, findsOneWidget);
    expect(tester.widget<Text>(completeTeamTwo).style?.color, AppColors.ink);
    expect(tester.takeException(), isNull);
  });

  testWidgets('puts availability guidance on an opaque high-contrast surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MatchRosterSummary(
            players: <Player>[],
            totalCount: 0,
            assignment: <String, int>{},
            enoughPlayers: false,
            neededMessage:
                'Servono almeno 4 giocatori presenti per una partita 2 VS 2.',
            onShowAll: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final guidance = find.text(
      'Servono almeno 4 giocatori presenti per una partita 2 VS 2.',
    );
    expect(guidance, findsOneWidget);
    expect(tester.widget<Text>(guidance).style?.color, AppColors.ink);
    final card = find.ancestor(of: guidance, matching: find.byType(Container));
    expect(card, findsOneWidget);
    final decoration =
        tester.widget<Container>(card).decoration! as BoxDecoration;
    expect(decoration.color, AppColors.surface.withValues(alpha: .94));
  });

  testWidgets('300 percent setup scrolls its growing kickoff action', (
    tester,
  ) async {
    await mount(tester, size: const Size(320, 568), textScale: 3);
    openSetup(tester);
    await tester.pumpAndSettle();

    final scroll = setupScroll();
    final teamTwoAdd = find.byKey(const ValueKey('add-team-2'));
    await tester.scrollUntilVisible(teamTwoAdd, 160, scrollable: scroll);
    await tester.pumpAndSettle();
    expect(tester.getRect(teamTwoAdd).bottom, lessThan(568));

    final kickoff = find.byKey(const ValueKey('setup-kickoff-action'));
    await tester.ensureVisible(kickoff);
    await tester.pumpAndSettle();
    final kickoffRect = tester.getRect(kickoff);
    final labelRect = tester.getRect(find.text('INIZIA PARTITA'));
    expect(kickoffRect.height, greaterThan(200));
    expect(labelRect.top, greaterThanOrEqualTo(kickoffRect.top));
    expect(labelRect.bottom, lessThanOrEqualTo(kickoffRect.bottom));
    expect(kickoffRect.bottom, lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('200 percent setup keeps the pinned kickoff below team actions', (
    tester,
  ) async {
    await mount(tester, size: const Size(402, 874), textScale: 2);
    openSetup(tester);
    await tester.pumpAndSettle();

    final scroll = setupScroll();
    final teamTwoAdd = find.byKey(const ValueKey('add-team-2'));
    await tester.scrollUntilVisible(teamTwoAdd, 160, scrollable: scroll);
    await Scrollable.ensureVisible(
      tester.element(teamTwoAdd),
      alignment: .35,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();

    final kickoff = tester.getRect(
      find.byKey(const ValueKey('setup-kickoff-action')),
    );
    expect(tester.getRect(teamTwoAdd).bottom, lessThanOrEqualTo(kickoff.top));
    expect(
      tester.getRect(find.text('INIZIA PARTITA')).bottom,
      lessThanOrEqualTo(kickoff.bottom),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('300 percent landscape keeps team rows and kickoff reachable', (
    tester,
  ) async {
    await mount(tester, size: const Size(568, 320), textScale: 3);
    openSetup(tester);
    await tester.pumpAndSettle();

    final scroll = setupScroll();
    final teamTwoAdd = find.byKey(const ValueKey('add-team-2'));
    await tester.scrollUntilVisible(teamTwoAdd, 160, scrollable: scroll);
    await tester.pumpAndSettle();
    expect(tester.getRect(teamTwoAdd).bottom, lessThanOrEqualTo(320));

    final position = tester.state<ScrollableState>(scroll).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('INIZIA PARTITA')).bottom,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
  });
}
