import 'package:biliardino/cubits/history/history_cubit.dart';
import 'package:biliardino/cubits/history/history_filters.dart';
import 'package:biliardino/navigation/app_navigation.dart';
import 'package:biliardino/screens/history_screen.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';
import '../support/history_design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);

  testWidgets(
    'live count, player rename, archive and match deletion update the real route',
    (tester) async {
      final fixture = await _pump(tester, count: 1);
      expect(find.text('1 partita'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('history-central-history-0')),
        findsOneWidget,
      );
      final player = fixture.playersRepository.players.first;
      await fixture.playersRepository.renamePlayer(player, 'Andrea Rossi');
      await fixture.playersRepository.archivePlayer(
        fixture.playersRepository.players.first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Andrea Rossi / Luca'), findsOneWidget);
      await fixture.matchesRepository.deleteMatch('history-0');
      await tester.pumpAndSettle();
      expect(find.text('0 partite'), findsOneWidget);
      expect(find.text('Nessuna partita'), findsOneWidget);
      expect(find.byKey(const ValueKey('history-reset-filters')), findsNothing);
    },
  );

  testWidgets(
    'filter draft cancel preserves results and filtered empty reset restores them',
    (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('history-open-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('history-filter-oneVsOne')));
      await tester.ensureVisible(find.text('Annulla'));
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(find.text('4 partite'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('history-open-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('history-filter-rivalry')));
      await tester.ensureVisible(
        find.byKey(const ValueKey('history-apply-filters')),
      );
      await tester.tap(find.byKey(const ValueKey('history-apply-filters')));
      await tester.pumpAndSettle();
      expect(find.text('0 partite'), findsOneWidget);
      expect(find.text('Nessuna partita trovata'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('history-reset-filters')));
      await tester.pumpAndSettle();
      expect(find.text('4 partite'), findsOneWidget);
    },
  );

  testWidgets(
    'scores stay paired with teams and overflow action does not open details',
    (tester) async {
      await _pump(tester, count: 1);
      final semantics = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(
            find.byKey(const ValueKey('history-team-history-0-team-2')),
          ),
          matchesSemantics(
            label: 'Squadra 2: Marco / Paolo, punteggio 5, vittoria',
          ),
        );
        expect(
          tester.getRect(find.text('4')).right,
          lessThan(tester.getRect(find.text('5')).left),
        );
        final menu = find.byTooltip('Azioni partita');
        expect(tester.getSize(menu).height, greaterThanOrEqualTo(48));
        await tester.tap(menu);
        await tester.pumpAndSettle();
        expect(find.text('Correggi'), findsOneWidget);
        expect(find.text('Dettagli partita'), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final viewport in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets(
      '200 percent text scrolls complete names, scores and filter reset at $viewport',
      (tester) async {
        await _pump(
          tester,
          count: 1,
          longNames: true,
          size: viewport,
          scale: 2,
        );
        final history = tester
            .element(find.byType(HistoryScreen))
            .read<HistoryCubit>();
        history.applyFilters(
          const HistoryFilters(matchMode: HistoryMatchModeFilter.twoVsTwo),
        );
        await tester.pumpAndSettle();
        final reset = find.byKey(const ValueKey('history-reset-filters'));
        expect(reset.hitTestable(), findsOneWidget);
        expect(tester.getSize(reset).height, greaterThanOrEqualTo(48));
        await tester.tap(reset);
        await tester.pumpAndSettle();
        final scrollable = find.descendant(
          of: find.byKey(const ValueKey('history-scroll')),
          matching: find.byType(Scrollable),
        );
        final name = find.text(
          'Alessandro Antonio Delgaudio / Beatrice Lunghissimo Cognome',
        );
        await tester.scrollUntilVisible(name, 150, scrollable: scrollable);
        final paragraph = tester.renderObject<RenderParagraph>(name);
        expect(paragraph.didExceedMaxLines, isFalse);
        for (final score in ['10', '12']) {
          await tester.scrollUntilVisible(
            find.text(score),
            150,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          expect(find.text(score).hitTestable(), findsOneWidget);
          expect(
            tester
                .renderObject<RenderParagraph>(find.text(score))
                .didExceedMaxLines,
            isFalse,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'many same-day cards remain lazy and the final match is reachable',
    (tester) async {
      await _pump(tester, count: 80, sameDay: true);
      final first = find.byKey(const ValueKey('history-match-history-0'));
      final last = find.byKey(const ValueKey('history-match-history-79'));
      expect(first, findsOneWidget);
      expect(last, findsNothing);
      final scrollable = find.descendant(
        of: find.byKey(const ValueKey('history-scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        last,
        450,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      expect(last.hitTestable(), findsOneWidget);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(find.text('Dettagli partita'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<DesignFixture> _pump(
  WidgetTester tester, {
  int count = 4,
  bool longNames = false,
  bool sameDay = false,
  Size size = const Size(402, 874),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = size.width > size.height
      ? const FakeViewPadding(left: 44, right: 44, bottom: 24)
      : const FakeViewPadding(top: 62, bottom: 34);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final fixture = historyDesignFixture(
    count: count,
    longNames: longNames,
    sameDay: sameDay,
  );
  await fixture.load();
  await tester.pumpWidget(fixture.home);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.dispose();
  });
  await tester.pumpAndSettle();
  openHistory(tester.element(find.byType(HomeScreen)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return fixture;
}
