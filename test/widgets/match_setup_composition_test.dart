import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);

  for (final size in [const Size(440, 956), const Size(402, 874)]) {
    testWidgets('Setup actions clear pinned kickoff at $size in both modes', (
      tester,
    ) async {
      tester.view.physicalSize = size;
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
      final kickoff = find.byKey(const ValueKey('setup-kickoff-action'));
      final scroll = find.descendant(
        of: find.byKey(const ValueKey('setup-scroll-view')),
        matching: find.byType(Scrollable),
      );

      for (final mode in MatchMode.values) {
        cubit.setMatchMode(mode);
        cubit.setTeam('p0', 1);
        cubit.setTeam('p3', 2);
        if (mode == MatchMode.twoVsTwo) {
          cubit.setTeam('p2', 1);
          cubit.setTeam('p4', 2);
        }
        await tester.pumpAndSettle();
        final pinnedRect = tester.getRect(kickoff);
        if (size.width == 440 && mode == MatchMode.twoVsTwo) {
          tester.state<ScrollableState>(scroll).position.jumpTo(0);
          await tester.pumpAndSettle();
          final stage = find.byKey(const ValueKey('setup-team-stage'));
          expect(tester.getRect(stage).bottom, lessThan(pinnedRect.top - 12));
        }
        final lastAdd = find.byKey(const ValueKey('add-team-2'));
        await tester.scrollUntilVisible(lastAdd, 100, scrollable: scroll);
        await Scrollable.ensureVisible(tester.element(lastAdd), alignment: .5);
        await tester.pumpAndSettle();
        expect(tester.getRect(kickoff), pinnedRect);
        expect(tester.getRect(lastAdd).bottom, lessThan(pinnedRect.top));
        expect(tester.getSize(lastAdd).height, greaterThanOrEqualTo(48));
        expect(tester.widget<ElevatedButton>(kickoff).onPressed, isNotNull);

        final playerName = find.text('ANDREA');
        final slot = find
            .ancestor(of: playerName, matching: find.byType(InkWell))
            .first;
        expect(tester.getSize(slot).height, greaterThanOrEqualTo(48));
        await tester.ensureVisible(slot);
        await tester.tap(slot);
        await tester.pumpAndSettle();
        expect(find.text('MODIFICA SQUADRA 1'), findsOneWidget);
        Navigator.of(tester.element(find.text('MODIFICA SQUADRA 1'))).pop();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
