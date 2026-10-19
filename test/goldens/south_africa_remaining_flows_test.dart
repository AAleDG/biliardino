import '../support/tab_transition_goldens.dart';
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../support/design_fixture.dart';

void main() {
  setUpAll(() async {
    await loadDesignFonts();
    await initializeDateFormatting('it_IT');
  });
  for (final compact in [false, true]) {
    testWidgets(
      'Remaining flows with real fonts at ${compact ? 'compact large text' : 'reference size'}',
      (tester) async {
        tester.view.physicalSize = compact
            ? const Size(320, 568)
            : const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = compact ? 2 : 1;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixture = DesignFixture();
        await fixture.load();
        await tester.pumpWidget(
          RepaintBoundary(key: const ValueKey('capture'), child: fixture.home),
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await fixture.dispose();
        });
        final context = tester.element(find.byType(HomeScreen));
        final home = context.read<HomeCubit>();
        Future<void> capture(String name) async {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('capture')),
            matchesGoldenFile(
              tabTransitionGolden(
                '${name == 'filters' ? 'reference-corrections/' : ''}'
                'south-africa-$name${compact ? '-compact' : ''}.png',
              ),
            ),
          );
        }

        home.select(HomeDestination.more);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('more-history')));
        await capture('history');
        await tester.tap(find.byKey(const ValueKey('history-open-filters')));
        await capture('filters');
        final apply = find.byKey(const ValueKey('history-apply-filters'));
        await tester.ensureVisible(apply);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(apply).bottom,
          lessThanOrEqualTo(tester.view.physicalSize.height - 34),
        );
        if (compact) await capture('filters-actions');
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
        home.select(HomeDestination.leaderboard);
        await capture('standings');
        await tester.ensureVisible(find.text('Marcatori'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Marcatori'));
        await capture('scorers');
        home.select(HomeDestination.more);
        await tester.pumpAndSettle();
        final data = find.byKey(const ValueKey('more-data'));
        await tester.ensureVisible(data);
        await tester.pumpAndSettle();
        await tester.tap(data);
        await capture('data');
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
        home.select(HomeDestination.players);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Andrea').first);
        await capture('profile');
        await tester.fling(
          find.byType(Scrollable).last,
          const Offset(0, -800),
          1500,
        );
        await capture('profile-history');
      },
    );
  }
}
