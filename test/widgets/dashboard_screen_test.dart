import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/screens/history_screen.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/screens/player_profile_screen.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

void main() {
  testWidgets(
    'Home renders the live reference composition and repository data',
    (tester) async {
      await _pumpFixture(tester, populatedDashboard: true);

      expect(find.text('BILIARDINO'), findsOneWidget);
      expect(find.text('GIOCA  •  SFIDA  •  VIVI LA PASSIONE'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('INIZIA PARTITA'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard-match-dashboard-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-match-dashboard-1')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('dashboard-ranking-p0')), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName.endsWith(
                'home-hero-transparent.png',
              ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home hero and primary action retain reference geometry', (
    tester,
  ) async {
    await _pumpFixture(tester, populatedDashboard: true);

    final hero = find.byKey(const ValueKey('dashboard-home-hero'));
    final heroImage = tester.widget<Image>(
      find.descendant(of: hero, matching: find.byType(Image)),
    );
    final heroSize = tester.getSize(hero);
    expect(heroSize.width, 402);
    expect(heroSize.height, closeTo(402 * 1038 / 1516, .01));
    expect(heroImage.fit, BoxFit.contain);

    final actionFinder = find.byKey(const ValueKey('dashboard-start-match'));
    final action = tester.widget<ElevatedButton>(actionFinder);
    final actionSize = tester.getSize(actionFinder);
    expect(tester.getTopLeft(actionFinder).dx, 16);
    expect(actionSize.width, 370);
    expect(actionSize.height, 72);
    expect(
      action.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.homeAction,
    );
    expect(action.style?.shape?.resolve(<WidgetState>{}), isA<StadiumBorder>());
    expect(
      action.style?.side?.resolve(<WidgetState>{}),
      const BorderSide(color: AppColors.onPrimary, width: 4),
    );
  });

  testWidgets('Home start and resume actions enter the existing match flow', (
    tester,
  ) async {
    await _pumpFixture(tester);
    final context = tester.element(find.byType(HomeScreen));
    final home = context.read<HomeCubit>();
    final match = context.read<NewMatchCubit>();

    await tester.tap(find.byKey(const ValueKey('dashboard-start-match')));
    await tester.pumpAndSettle();
    expect(home.state, HomeDestination.match);
    expect(find.text('NUOVA PARTITA'), findsOneWidget);

    match.setMatchMode(MatchMode.oneVsOne);
    match.setTeam('p0', 1);
    match.setTeam('p3', 2);
    match.kickoff();
    home.select(HomeDestination.home);
    await tester.pumpAndSettle();
    expect(find.text('RIPRENDI PARTITA'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard-start-match')));
    await tester.pump();
    expect(home.state, HomeDestination.match);
    expect(match.state.kickedOff, isTrue);
    expect(match.state.assignment, {'p0': 1, 'p3': 2});
  });

  testWidgets('section and row actions open the full owned destinations', (
    tester,
  ) async {
    await _pumpFixture(tester, populatedDashboard: true);
    final context = tester.element(find.byType(HomeScreen));
    final home = context.read<HomeCubit>();

    await tester.tap(find.text('VEDI TUTTE'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(HistoryScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dashboard-match-dashboard-5')));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(HistoryScreen))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('dashboard-ranking-p0')),
    );
    await tester.tap(find.byKey(const ValueKey('dashboard-ranking-p0')).first);
    await tester.pumpAndSettle();
    expect(find.byType(PlayerProfileScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(PlayerProfileScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('VEDI TUTTI'));
    await tester.pumpAndSettle();
    expect(home.state, HomeDestination.leaderboard);
    expect(find.text('CLASSIFICA'), findsWidgets);
  });

  testWidgets('empty Home explains both sections without fixture content', (
    tester,
  ) async {
    await _pumpFixture(tester, empty: true);

    expect(find.text('Nessuna partita registrata'), findsOneWidget);
    expect(find.text('Classifica ancora vuota'), findsOneWidget);
    expect(find.text('Andrea'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sparse and long-name content reflows without invented fixtures',
    (tester) async {
      await _pumpFixture(tester, sparseDashboard: true);
      expect(
        find.byKey(const ValueKey('dashboard-match-dashboard-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-ranking-p0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-ranking-p1')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('dashboard-ranking-p2')), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      final longFixture = DesignFixture(
        longRoster: true,
        populatedDashboard: true,
      );
      await longFixture.load();
      await tester.pumpWidget(longFixture.home);
      await tester.pumpAndSettle();
      addTearDown(longFixture.dispose);
      expect(
        find.text(
          'Alessandro Antonio Delgaudio – Beatrice Lunghissimo Cognome',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home exposes concise traversal labels for live controls and rows',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpFixture(tester, populatedDashboard: true);

      expect(
        find.bySemanticsLabel('Biliardino. Gioca, sfida, vivi la passione.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('inizia partita', caseSensitive: false)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Calciatori da biliardino, pallone e nastri nei colori del Sudafrica.',
        ),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(
          'Andrea – Giulia, 5 - 3, 8 set. Apri lo storico.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(r'Posizione 1, .+, [0-9]+ punti\. Apri il profilo\.'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'compact 200 percent layout scrolls while navigation stays fixed',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 20);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpFixture(
        tester,
        populatedDashboard: true,
        preserveViewport: true,
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('CLASSIFICA').first,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('CLASSIFICA'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dashboard actions preserve minimum touch target dimensions', (
    tester,
  ) async {
    await _pumpFixture(tester, populatedDashboard: true);

    for (final finder in [
      find.byKey(const ValueKey('dashboard-start-match')),
      find.byKey(const ValueKey('dashboard-match-dashboard-5')),
      find.byKey(const ValueKey('dashboard-ranking-p0')).first,
    ]) {
      final size = tester.getSize(finder);
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });
}

Future<DesignFixture> _pumpFixture(
  WidgetTester tester, {
  bool empty = false,
  bool populatedDashboard = false,
  bool sparseDashboard = false,
  bool preserveViewport = false,
}) async {
  if (!preserveViewport) {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);
  }
  final fixture = DesignFixture(
    empty: empty,
    populatedDashboard: populatedDashboard,
    sparseDashboard: sparseDashboard,
  );
  await fixture.load();
  await tester.pumpWidget(fixture.home);
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.dispose();
  });
  return fixture;
}
