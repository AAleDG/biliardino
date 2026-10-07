import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/presentation/italia90/screens/home_screen.dart'
    as italia;
import 'dart:async';
import 'package:biliardino/cubits/app_style/app_style_cubit.dart';
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/history/history_cubit.dart';
import 'package:biliardino/cubits/history/history_filters.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/navigation/app_navigation.dart';
import 'package:biliardino/presentation/app_presentation.dart';
import 'package:biliardino/presentation/presentation_registry.dart';
import 'package:biliardino/presentation/south_africa/south_africa_presentation.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/screens/history_screen.dart';
import 'package:biliardino/screens/match_editor/match_editor_screen.dart';
import 'package:biliardino/screens/player_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';
import '../support/match_editor_fixture.dart' show editorTap;

void main() {
  testWidgets(
    'two real styles retain setup, filters, ranking mode/tab and the Navigator',
    (tester) async {
      final fixture = DesignFixture();
      await fixture.load();
      await tester.pumpWidget(fixture.app);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(HomeScreen));
      final home = context.read<HomeCubit>();
      final match = context.read<NewMatchCubit>();
      final style = context.read<AppStyleCubit>();
      final ranks = context.read<LeaderboardCubit>();
      final history = context.read<HistoryCubit>();
      final nav = Navigator.of(context);
      home.select(HomeDestination.match);
      match.setTeam('p0', 1);
      match.setTeam('p3', 2);
      history.applyFilters(
        const HistoryFilters(matchMode: HistoryMatchModeFilter.twoVsTwo),
      );
      ranks.selectMode(MatchMode.oneVsOne);
      ranks.selectTab(1);
      home.select(HomeDestination.more);
      await tester.pumpAndSettle();
      for (final target in [
        AppStyle.italia90,
        AppStyle.southAfrica2010,
        AppStyle.italia90,
      ]) {
        await style.select(target);
        await tester.pumpAndSettle();
        final screen = target == AppStyle.italia90
            ? find.byType(italia.HomeScreen)
            : find.byType(HomeScreen);
        final current = tester.element(screen);
        expect(current.read<NewMatchCubit>(), same(match));
        expect(current.read<HomeCubit>(), same(home));
        expect(current.read<LeaderboardCubit>(), same(ranks));
        expect(Navigator.of(current), same(nav));
        expect(match.state.assignment, {'p0': 1, 'p3': 2});
        expect(
          history.state.filters.matchMode,
          HistoryMatchModeFilter.twoVsTwo,
        );
        expect(ranks.state.selectedMode, MatchMode.oneVsOne);
        expect(ranks.state.selectedTab, 1);
        expect(home.state, HomeDestination.more);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    },
  );

  testWidgets(
    'inactive presentation does not consume a second goal or save effect',
    (tester) async {
      final fixture = DesignFixture();
      await fixture.load();
      await tester.pumpWidget(fixture.app);
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(HomeScreen));
      final home = ctx.read<HomeCubit>();
      final match = ctx.read<NewMatchCubit>();
      final style = ctx.read<AppStyleCubit>();
      await style.select(AppStyle.italia90);
      await tester.pumpAndSettle();
      await style.select(AppStyle.southAfrica2010);
      await tester.pumpAndSettle();
      home.select(HomeDestination.match);
      match.setMatchMode(MatchMode.oneVsOne);
      match.setTeam('p0', 1);
      match.setTeam('p3', 2);
      match.kickoff();
      match.addGoal(1, 'p0');
      await tester.pumpAndSettle();
      expect(match.state.score1, 1);
      expect(match.state.scorerIds, ['p0']);
      await style.select(AppStyle.italia90);
      await tester.pumpAndSettle();
      expect(match.state.score1, 1);
      expect(match.state.kickedOff, isTrue);
      final barrier = Completer<void>();
      fixture.database.matchInsertBarrier = barrier.future;
      final save = match.save();
      await tester.pump();
      await style.select(AppStyle.southAfrica2010);
      await tester.pump();
      barrier.complete();
      await save;
      await tester.pumpAndSettle();
      expect(fixture.database.insertMatchCalls, 1);
      expect(find.text('HAI VINTO!'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    },
  );

  testWidgets(
    'production composition keeps owners, setup and active match on rebuild',
    (tester) async {
      final fixture = DesignFixture();
      await fixture.load();
      await tester.pumpWidget(fixture.app);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(HomeScreen));
      final home = context.read<HomeCubit>();
      final match = context.read<NewMatchCubit>();
      final style = context.read<AppStyleCubit>();
      final navigator = Navigator.of(context);
      expect(AppStyle.values, [AppStyle.southAfrica2010, AppStyle.italia90]);
      expect(presentationFor(style.state), isA<SouthAfricaPresentation>());
      expect(find.text('Italia'), findsNothing);
      home.select(HomeDestination.match);
      match.setMatchMode(MatchMode.oneVsOne);
      match.setTeam('p0', 1);
      await tester.pumpWidget(fixture.app);
      await tester.pumpAndSettle();
      expect(match.state.assignment, {'p0': 1});
      match.setTeam('p3', 2);
      match.kickoff();
      match.addGoal(1, 'p0');
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final selection = expectLater(
        style.stream,
        emits(AppStyle.southAfrica2010),
      );
      await style.select(AppStyle.southAfrica2010);
      await selection;
      await tester.pumpAndSettle();
      // The first explicit selection emits even when equal to the initial state.
      // Verify the real BlocBuilder rebuilt without a manual parent rebuild.
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)),
        isNot(same(materialApp)),
      );
      final after = tester.element(find.byType(HomeScreen));
      expect(after.read<NewMatchCubit>(), same(match));
      expect(after.read<HomeCubit>(), same(home));
      expect(after.read<PlayerRepository>(), same(fixture.playersRepository));
      expect(Navigator.of(after), same(navigator));
      expect(home.state, HomeDestination.match);
      expect(match.state.score1, 1);
      expect(match.state.scorerIds, ['p0']);
      expect(match.state.kickedOff, isTrue);
      // Save completion must also survive a parent/presentation rebuild.
      final barrier = Completer<void>();
      fixture.database.matchInsertBarrier = barrier.future;
      final saving = match.save();
      await tester.pump();
      expect(match.state.isSaving, isTrue);
      await tester.pumpWidget(fixture.app);
      await tester.pump();
      expect(after.read<NewMatchCubit>(), same(match));
      barrier.complete();
      await saving;
      await tester.pumpAndSettle();
      expect(fixture.database.insertMatchCalls, 1);
      expect(fixture.matchesRepository.matches.first.t1Score, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    },
  );

  testWidgets(
    'real presentation rebinding preserves pushed routes, filters and dirty editor',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fixture = DesignFixture();
      await fixture.load();
      final first = _ObservedSouthAfrica();
      await tester.pumpWidget(fixture.homeWithPresentation(first));
      await tester.pumpAndSettle();
      var context = tester.element(find.byType(HomeScreen));
      final history = context.read<HistoryCubit>();
      history.applyFilters(
        const HistoryFilters(matchMode: HistoryMatchModeFilter.twoVsTwo),
      );
      openHistory(context);
      await tester.pumpAndSettle();
      final historyRoute = ModalRoute.of(
        tester.element(find.byType(HistoryScreen)),
      );
      final second = _ObservedSouthAfrica();
      await tester.pumpWidget(fixture.homeWithPresentation(second));
      await tester.pumpAndSettle();
      expect(second.pages, contains(AppPage.history));
      expect(
        ModalRoute.of(tester.element(find.byType(HistoryScreen))),
        same(historyRoute),
      );
      expect(history.state.filters.matchMode, HistoryMatchModeFilter.twoVsTwo);
      await tester.tap(find.byTooltip('Azioni partita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Correggi'));
      await tester.pumpAndSettle();
      await editorTap(tester, find.byTooltip('Aumenta Punteggio squadra 1'));
      final editor = tester.state(find.byType(MatchEditorScreen));
      final third = _ObservedSouthAfrica();
      await tester.pumpWidget(fixture.homeWithPresentation(third));
      await tester.pumpAndSettle();
      expect(third.editorBuilds, greaterThan(0));
      expect(tester.state(find.byType(MatchEditorScreen)), same(editor));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('edit-score-1'))).data,
        '5',
      );
      await editorTap(tester, find.text('Annulla'));
      expect(find.text('Scartare le modifiche?'), findsOneWidget);
      await editorTap(tester, find.text('Scarta'));
      expect(fixture.database.updateMatchCalls, 0);
      Navigator.of(tester.element(find.byType(HistoryScreen))).pop();
      await tester.pumpAndSettle();
      context = tester.element(find.byType(HomeScreen));
      openPlayerProfile(context, 'p0');
      await tester.pumpAndSettle();
      final profile = ModalRoute.of(
        tester.element(find.byType(PlayerProfileScreen)),
      );
      final fourth = _ObservedSouthAfrica();
      await tester.pumpWidget(fixture.homeWithPresentation(fourth));
      await tester.pumpAndSettle();
      expect(fourth.profiles, isNotEmpty);
      expect(fourth.profiles, everyElement('p0'));
      expect(
        ModalRoute.of(tester.element(find.byType(PlayerProfileScreen))),
        same(profile),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    },
  );
}

/// Records dispatch while rendering only the real, unchanged South Africa UI.
class _ObservedSouthAfrica extends SouthAfricaPresentation {
  final pages = <AppPage>[];
  final profiles = <String>[];
  int editorBuilds = 0;
  @override
  Widget page(AppPage page) {
    pages.add(page);
    return super.page(page);
  }

  @override
  Widget profile(String playerId) {
    profiles.add(playerId);
    return super.profile(playerId);
  }

  @override
  Widget matchEditor({
    required GameMatch match,
    required List<Player> players,
    required Future<void> Function(GameMatch) onSave,
  }) {
    editorBuilds++;
    return super.matchEditor(match: match, players: players, onSave: onSave);
  }
}
