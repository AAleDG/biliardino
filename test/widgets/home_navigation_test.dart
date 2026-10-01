import 'dart:async';

import 'package:biliardino/cubits/history/history_cubit.dart';
import 'package:biliardino/cubits/history/history_filters.dart';
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/screens/dashboard_screen.dart';
import 'package:biliardino/screens/history_screen.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

void main() {
  testWidgets('Home is initial and all five named destinations are reachable', (
    tester,
  ) async {
    await _pumpFixture(tester);
    final context = tester.element(find.byType(HomeScreen));
    final home = context.read<HomeCubit>();

    expect(home.state, HomeDestination.home);
    expect(find.byType(DashboardScreen), findsOneWidget);
    for (final entry in const [
      ('Giocatori', HomeDestination.players, 'GIOCATORI'),
      ('Partita', HomeDestination.match, 'NUOVA PARTITA'),
      ('Classifica', HomeDestination.leaderboard, 'CLASSIFICA'),
      ('Altro', HomeDestination.more, 'ALTRO'),
    ]) {
      await tester.tap(find.text(entry.$1));
      await tester.pumpAndSettle();
      expect(home.state, entry.$2);
      expect(find.text(entry.$3), findsOneWidget);
    }
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(home.state, HomeDestination.home);
  });

  testWidgets('Altro opens full routes and preserves History filters', (
    tester,
  ) async {
    await _pumpFixture(tester);
    final context = tester.element(find.byType(HomeScreen));
    final history = context.read<HistoryCubit>();
    history.applyFilters(
      const HistoryFilters(matchMode: HistoryMatchModeFilter.twoVsTwo),
    );

    await tester.tap(find.text('Altro'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('more-history')));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(history.state.filters.matchMode, HistoryMatchModeFilter.twoVsTwo);

    Navigator.of(tester.element(find.byType(HistoryScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('more-history')));
    await tester.pumpAndSettle();
    expect(history.state.filters.matchMode, HistoryMatchModeFilter.twoVsTwo);

    Navigator.of(tester.element(find.byType(HistoryScreen))).pop();
    await tester.pumpAndSettle();
    final data = find.byKey(const ValueKey('more-data'));
    await Scrollable.ensureVisible(tester.element(data), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(data);
    await tester.pumpAndSettle();
    expect(find.text('ESPORTA'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('setup survives ordinary tab changes', (tester) async {
    await _pumpFixture(tester);
    final context = tester.element(find.byType(HomeScreen));
    final match = context.read<NewMatchCubit>();

    context.read<HomeCubit>().select(HomeDestination.match);
    match.setMatchMode(MatchMode.oneVsOne);
    match.setTeam('p0', 1);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giocatori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partita'));
    await tester.pumpAndSettle();

    expect(match.state.assignment, {'p0': 1});
    expect(match.state.kickedOff, isFalse);
  });

  testWidgets('returning to an active match preserves its live state', (
    tester,
  ) async {
    await _pumpFixture(tester);
    final context = tester.element(find.byType(HomeScreen));
    final home = context.read<HomeCubit>();
    final match = context.read<NewMatchCubit>();
    home.select(HomeDestination.match);
    match.setMatchMode(MatchMode.oneVsOne);
    match.setTeam('p0', 1);
    match.setTeam('p3', 2);
    match.kickoff();
    match.addGoal(1, 'p0');
    await tester.pump();

    home.select(HomeDestination.home);
    await tester.pump();
    home.select(HomeDestination.match);
    await tester.pump();

    expect(match.state.kickedOff, isTrue);
    expect(match.state.score1, 1);
    expect(match.state.score2, 0);
    expect(match.state.assignment, {'p0': 1, 'p3': 2});
  });

  testWidgets('navigation waits for an in-flight match save', (tester) async {
    final fixture = await _pumpFixture(tester);
    final context = tester.element(find.byType(HomeScreen));
    final home = context.read<HomeCubit>();
    final match = context.read<NewMatchCubit>();
    home.select(HomeDestination.match);
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

    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(home.state, HomeDestination.match);
    expect(find.text('Uscire dalla partita?'), findsNothing);

    barrier.complete();
    await saving;
    await tester.pump();
    expect(fixture.database.matches, hasLength(2));
  });

  testWidgets(
    'started match departure keeps the established cancel and abort paths',
    (tester) async {
      await _pumpFixture(tester);
      final context = tester.element(find.byType(HomeScreen));
      final home = context.read<HomeCubit>();
      final match = context.read<NewMatchCubit>();
      home.select(HomeDestination.match);
      match.setMatchMode(MatchMode.oneVsOne);
      match.setTeam('p0', 1);
      match.setTeam('p3', 2);
      match.kickoff();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Uscire dalla partita?'), findsOneWidget);
      await tester.tap(find.text('Resta'));
      await tester.pumpAndSettle();
      expect(home.state, HomeDestination.match);
      expect(match.state.kickedOff, isTrue);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();
      expect(home.state, HomeDestination.home);
      expect(match.state.kickedOff, isFalse);
      expect(match.state.assignment, {'p0': 1, 'p3': 2});
      expect(match.state.score1, 0);
      expect(match.state.score2, 0);
    },
  );

  testWidgets('system back preserves the active-match confirmation guard', (
    tester,
  ) async {
    await _pumpFixture(tester);
    final context = tester.element(find.byType(HomeScreen));
    final home = context.read<HomeCubit>();
    final match = context.read<NewMatchCubit>();
    home.select(HomeDestination.match);
    match.setMatchMode(MatchMode.oneVsOne);
    match.setTeam('p0', 1);
    match.setTeam('p3', 2);
    match.kickoff();
    final guardedRoute = MaterialPageRoute<void>(
      builder: (_) => const HomeScreen(),
    );
    Navigator.of(context).push(guardedRoute);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Uscire dalla partita?'), findsOneWidget);
    await tester.tap(find.text('Resta'));
    await tester.pumpAndSettle();
    expect(guardedRoute.isActive, isTrue);
    expect(match.state.kickedOff, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();
    expect(guardedRoute.isActive, isFalse);
    expect(match.state.kickedOff, isFalse);
  });
}

Future<DesignFixture> _pumpFixture(WidgetTester tester) async {
  final fixture = DesignFixture();
  await fixture.load();
  await tester.pumpWidget(fixture.home);
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.dispose();
  });
  return fixture;
}
