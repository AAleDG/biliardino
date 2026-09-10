import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';

void main() {
  Future<DesignFixture> mount(
    WidgetTester tester, {
    bool empty = false,
    bool longRoster = false,
    Size size = const Size(402, 874),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final fixture = DesignFixture(empty: empty, longRoster: longRoster);
    await fixture.load();
    await tester.pumpWidget(fixture.home);
    tester
        .element(find.byType(HomeScreen))
        .read<HomeCubit>()
        .select(HomeDestination.players);
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
    return fixture;
  }

  testWidgets('Presence and overflow actions remain independent of profile', (
    tester,
  ) async {
    final fixture = await mount(tester, scale: 2, longRoster: true);
    final presence = find.byKey(const ValueKey('player-presence-p0'));
    await tester.ensureVisible(presence);
    await tester.tap(presence);
    await tester.pumpAndSettle();
    expect(
      fixture.database.players.firstWhere((p) => p.id == 'p0').isPresent,
      isFalse,
    );
    expect(find.text('GIOCATORI'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('player-actions-p0')));
    await tester.pumpAndSettle();
    expect(find.text('Modifica nome'), findsOneWidget);
    expect(fixture.database.updatePlayerCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Full roster and team picker remain operable above kickoff at 200 percent',
    (tester) async {
      await mount(tester, scale: 2, longRoster: true);
      final context = tester.element(find.byType(HomeScreen));
      context.read<HomeCubit>().select(HomeDestination.match);
      await tester.pumpAndSettle();
      final setupScroll = find.descendant(
        of: find.byKey(const ValueKey('setup-scroll-view')),
        matching: find.byType(Scrollable),
      );
      final showAll = find.text('VEDI TUTTI (8)');
      await tester.scrollUntilVisible(showAll, 160, scrollable: setupScroll);
      await Scrollable.ensureVisible(
        tester.element(showAll),
        alignment: .5,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(showAll);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('present-player-p7')), findsNothing);
      final lastRosterPlayer = find.byKey(
        const ValueKey('roster-sheet-player-p7'),
      );
      final sheetScroll = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        lastRosterPlayer,
        120,
        scrollable: sheetScroll,
      );
      expect(find.text('Beatrice Lunghissimo Cognome'), findsOneWidget);
      Navigator.of(tester.element(lastRosterPlayer)).pop();
      await tester.pumpAndSettle();

      final add = find.byKey(const ValueKey('add-team-2'));
      await tester.scrollUntilVisible(add, 160, scrollable: setupScroll);
      await Scrollable.ensureVisible(
        tester.element(add),
        alignment: .4,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      final chip = find.byKey(const ValueKey('team-chip-p7-team-2'));
      final teamSheetScroll = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(chip, 120, scrollable: teamSheetScroll);
      await Scrollable.ensureVisible(
        tester.element(chip),
        alignment: .5,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(context.read<NewMatchCubit>().state.team2, contains('p7'));
      final assignedName = find.text('Beatrice Lunghissimo Cognome');
      expect(assignedName, findsOneWidget);
      final assignedSlot = find
          .ancestor(of: assignedName, matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(assignedSlot).height, greaterThan(54));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Open roster reflects assignment and presence invalidation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final fixture = await mount(tester, longRoster: true);
    final context = tester.element(find.byType(HomeScreen));
    context.read<HomeCubit>().select(HomeDestination.match);
    await tester.pumpAndSettle();

    final setupScroll = find.descendant(
      of: find.byKey(const ValueKey('setup-scroll-view')),
      matching: find.byType(Scrollable),
    );
    final showAll = find.text('VEDI TUTTI (8)');
    await tester.scrollUntilVisible(showAll, 160, scrollable: setupScroll);
    await tester.tap(showAll);
    await tester.pumpAndSettle();

    const playerId = 'p7';
    const playerName = 'Beatrice Lunghissimo Cognome';
    final rosterRow = find.byKey(
      const ValueKey('roster-sheet-player-$playerId'),
    );
    expect(rosterRow, findsOneWidget);

    final cubit = context.read<NewMatchCubit>();
    cubit.setTeam(playerId, 1);
    await tester.pumpAndSettle();
    expect(cubit.state.assignment[playerId], 1);
    final rowSemantics = tester.widget<Semantics>(
      find.descendant(of: rosterRow, matching: find.byType(Semantics)).first,
    );
    expect(rowSemantics.properties.label, '$playerName, Squadra 1');

    final player = fixture.database.players.firstWhere(
      (candidate) => candidate.id == playerId,
    );
    await fixture.playersRepository.togglePresent(player);
    await tester.pumpAndSettle();

    expect(rosterRow, findsNothing);
    expect(cubit.state.assignment, isNot(contains(playerId)));
    semantics.dispose();
  });

  testWidgets('Open team picker removes players that become unavailable', (
    tester,
  ) async {
    final fixture = await mount(tester, longRoster: true);
    final context = tester.element(find.byType(HomeScreen));
    context.read<HomeCubit>().select(HomeDestination.match);
    await tester.pumpAndSettle();

    final setupScroll = find.descendant(
      of: find.byKey(const ValueKey('setup-scroll-view')),
      matching: find.byType(Scrollable),
    );
    final add = find.byKey(const ValueKey('add-team-1'));
    await tester.scrollUntilVisible(add, 160, scrollable: setupScroll);
    await Scrollable.ensureVisible(
      tester.element(add),
      alignment: .4,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();

    const playerId = 'p7';
    final candidate = find.byKey(const ValueKey('team-chip-$playerId-team-1'));
    final teamSheetScroll = find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      candidate,
      120,
      scrollable: teamSheetScroll,
    );
    await Scrollable.ensureVisible(
      tester.element(candidate),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    expect(candidate, findsOneWidget);
    expect(
      tester.getRect(candidate).bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height - 34),
    );

    final player = fixture.database.players.firstWhere(
      (item) => item.id == playerId,
    );
    await fixture.playersRepository.togglePresent(player);
    await tester.pumpAndSettle();

    expect(candidate, findsNothing);
    expect(find.text('AGGIUNGI A SQUADRA 1'), findsOneWidget);
  });

  testWidgets('Empty setup can scroll to all guidance in compact landscape', (
    tester,
  ) async {
    await mount(tester, empty: true, scale: 2, size: const Size(568, 320));
    tester
        .element(find.byType(HomeScreen))
        .read<HomeCubit>()
        .select(HomeDestination.match);
    await tester.pumpAndSettle();
    final setupScroll = find.descendant(
      of: find.byKey(const ValueKey('setup-scroll-view')),
      matching: find.byType(Scrollable),
    );
    final guidance = find.text('Vai su Giocatori e segna chi è presente.');
    final position = tester.state<ScrollableState>(setupScroll).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(guidance).bottom, lessThan(320));
  });
}
