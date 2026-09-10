import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  testWidgets(
    'Populated roster and both setup scroll positions use real fonts',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
      addTearDown(tester.view.reset);
      final fixture = DesignFixture();
      await fixture.load();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('screen-capture'),
          child: fixture.home,
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await fixture.dispose();
      });
      Future<void> capture(String name) async {
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('screen-capture')),
          matchesGoldenFile('$name.png'),
        );
      }

      final context = tester.element(find.byType(HomeScreen));
      context.read<HomeCubit>().select(HomeDestination.players);
      await tester.pumpAndSettle();
      await capture('south-africa-players');
      context.read<HomeCubit>().select(HomeDestination.match);
      final match = context.read<NewMatchCubit>();
      match.setTeam('p0', 1);
      match.setTeam('p2', 1);
      match.setTeam('p3', 2);
      match.setTeam('p4', 2);
      await tester.pumpAndSettle();
      await capture('south-africa-setup-top');
      final last = find.byKey(const ValueKey('add-team-2'));
      final setupScroll = find.descendant(
        of: find.byKey(const ValueKey('setup-scroll-view')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(last, 120, scrollable: setupScroll);
      await Scrollable.ensureVisible(tester.element(last), alignment: .6);
      await tester.pumpAndSettle();
      await capture('south-africa-setup-players');
      tester.state<ScrollableState>(setupScroll).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('setup-options-action')));
      await tester.pumpAndSettle();
      await capture('south-africa-setup-options-free');
      await tester.tap(find.text('Primo a N'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scarto di 2 goal'));
      await tester.pumpAndSettle();
      await capture('south-africa-setup-options-target');
    },
  );
}
