import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/navigation/app_navigation.dart';
import 'package:biliardino/presentation/italia90/screens/history/history_match_card.dart';
import 'package:biliardino/presentation/italia90/screens/history_screen.dart';
import 'package:biliardino/presentation/italia90/screens/home_screen.dart';
import 'package:biliardino/presentation/italia90/theme/italia90_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';
import '../support/history_design_fixture.dart';

void main() {
  setUpAll(() async {
    await loadDesignFonts();
    for (final entry in {
      'Anton': ['assets/fonts/Anton-Regular.ttf'],
      'Italia Barlow': [
        'assets/fonts/Barlow-Regular.ttf',
        'assets/fonts/Barlow-Bold.ttf',
      ],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    }
  });

  testWidgets('compact history keeps actions reachable while scrolling', (
    tester,
  ) async {
    final fixture = historyDesignFixture(count: 6);
    await _pumpHistory(tester, fixture, const Size(320, 568));
    addTearDown(fixture.dispose);

    expect(find.byType(HistoryMatchCard), findsWidgets);
    final menu = find.byTooltip('Azioni partita').first;
    expect(tester.getSize(menu).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(menu).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('../goldens/italia90-history-compact.png'),
    );

    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('history-scroll')),
      matching: find.byType(Scrollable),
    );
    final lastMatch = find.byKey(const ValueKey('history-match-history-5'));
    await tester.scrollUntilVisible(
      lastMatch,
      240,
      maxScrolls: 30,
      scrollable: scrollable,
    );
    expect(lastMatch.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large history text grows cards without clipping player names', (
    tester,
  ) async {
    final fixture = historyDesignFixture(count: 4, longNames: true);
    await _pumpHistory(tester, fixture, const Size(402, 874), textScale: 2);
    addTearDown(fixture.dispose);

    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('history-scroll')),
      matching: find.byType(Scrollable),
    );
    final longName = find.text(
      'Alessandro Antonio Delgaudio / Beatrice Lunghissimo Cognome',
    );
    await tester.scrollUntilVisible(
      longName,
      180,
      maxScrolls: 30,
      scrollable: scrollable,
    );

    final paragraph = tester.renderObject<RenderParagraph>(longName);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.getSize(find.byTooltip('Azioni partita').first).height, 48);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history filter choices use equal slots and centered labels', (
    tester,
  ) async {
    final fixture = historyDesignFixture(count: 6);
    await _pumpHistory(tester, fixture, const Size(402, 874));
    addTearDown(fixture.dispose);

    await tester.tap(find.byKey(const ValueKey('history-open-filters')));
    await tester.pumpAndSettle();

    final allFilterChips = find.byKey(const ValueKey('history-filter-all'));
    final formatChips = [
      allFilterChips.at(0),
      find.byKey(const ValueKey('history-filter-oneVsOne')),
      find.byKey(const ValueKey('history-filter-rivalry')),
      find.byKey(const ValueKey('history-filter-twoVsTwo')),
    ];
    final formatWidth = tester.getSize(formatChips.first).width;
    for (final chip in formatChips) {
      expect(tester.getSize(chip).width, closeTo(formatWidth, 0.01));
      expect(tester.getSize(chip).height, closeTo(48, 0.01));
    }

    final centeredLabels = [
      (formatChips[0], 'Tutti i formati'),
      (formatChips[1], '1v1'),
      (formatChips[2], 'Rivalità'),
      (formatChips[3], '2v2'),
    ];
    for (final (chip, label) in centeredLabels) {
      final chipCenter = tester.getCenter(chip);
      final labelCenter = tester.getCenter(
        find.descendant(of: chip, matching: find.text(label)),
      );
      expect((chipCenter.dx - labelCenter.dx).abs(), lessThan(1));
      expect((chipCenter.dy - labelCenter.dy).abs(), lessThan(1));
    }

    final resultChips = [
      allFilterChips.at(2),
      find.byKey(const ValueKey('history-filter-wins')),
      find.byKey(const ValueKey('history-filter-losses')),
    ];
    final resultWidth = tester.getSize(resultChips.first).width;
    for (final chip in resultChips) {
      expect(tester.getSize(chip).width, closeTo(resultWidth, 0.01));
      expect(tester.getSize(chip).height, closeTo(48, 0.01));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('history filter labels stay centered with large text', (
    tester,
  ) async {
    final fixture = historyDesignFixture(count: 6);
    await _pumpHistory(tester, fixture, const Size(320, 568), textScale: 2);
    addTearDown(fixture.dispose);

    await tester.tap(find.byKey(const ValueKey('history-open-filters')));
    await tester.pumpAndSettle();

    void expectCentered(Finder chip, String label) {
      final labelFinder = find.descendant(of: chip, matching: find.text(label));
      expect(labelFinder, findsOneWidget);
      final chipCenter = tester.getCenter(chip);
      final labelCenter = tester.getCenter(labelFinder);
      expect((chipCenter.dx - labelCenter.dx).abs(), lessThan(1));
      expect((chipCenter.dy - labelCenter.dy).abs(), lessThan(1));
      expect(tester.getSize(chip).height, greaterThan(48));
    }

    final allFilterChips = find.byKey(const ValueKey('history-filter-all'));
    expectCentered(allFilterChips.at(0), 'Tutti i formati');
    expectCentered(
      find.byKey(const ValueKey('history-filter-oneVsOne')),
      '1v1',
    );
    expectCentered(
      find.byKey(const ValueKey('history-filter-rivalry')),
      'Rivalità',
    );
    expectCentered(
      find.byKey(const ValueKey('history-filter-twoVsTwo')),
      '2v2',
    );
    expectCentered(allFilterChips.at(1), 'Tutti i risultati');
    expectCentered(find.byKey(const ValueKey('history-filter-today')), 'Oggi');
    expectCentered(
      find.byKey(const ValueKey('history-filter-last7Days')),
      'Ultimi 7 giorni',
    );
    expectCentered(
      find.byKey(const ValueKey('history-filter-last30Days')),
      'Ultimi 30 giorni',
    );
    expectCentered(find.byKey(const ValueKey('history-player-all')), 'Tutti');
    expectCentered(allFilterChips.at(2), 'Tutte');
    expectCentered(find.byKey(const ValueKey('history-filter-wins')), 'Vinte');
    expectCentered(
      find.byKey(const ValueKey('history-filter-losses')),
      'Perse',
    );

    final disabledResultChip = allFilterChips.at(2);
    final disabledMaterial = find.descendant(
      of: disabledResultChip,
      matching: find.byType(Material),
    );
    expect(
      tester.widget<Material>(disabledMaterial).color,
      Italia90.subtle.withValues(alpha: 0.45),
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: disabledResultChip,
              matching: find.text('Tutte'),
            ),
          )
          .style
          ?.color,
      Italia90.muted,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('history details reflow metadata and actions with large text', (
    tester,
  ) async {
    final fixture = historyDesignFixture(count: 1, longNames: true);
    await _pumpHistory(tester, fixture, const Size(320, 568), textScale: 2);
    addTearDown(fixture.dispose);

    final match = find.byKey(const ValueKey('history-match-history-0'));
    final historyScroll = find.byKey(const ValueKey('history-scroll'));
    await tester.drag(historyScroll, const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.ensureVisible(match);
    await tester.tap(match);
    await tester.pumpAndSettle();

    final dateLabel = find.text('Data e ora');
    final dateValue = find.text('07/01/2026 · 13:30');
    expect(dateLabel, findsOneWidget);
    expect(dateValue, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(dateLabel).text.style?.fontSize,
      16,
    );
    expect(
      tester.renderObject<RenderParagraph>(dateValue).text.style?.fontSize,
      20,
    );
    expect(
      tester.getRect(dateValue).top,
      greaterThanOrEqualTo(tester.getRect(dateLabel).bottom),
    );

    final detailsScroll = find.byType(Scrollable).last;
    final edit = find.byKey(const ValueKey('match-details-edit'));
    await tester.scrollUntilVisible(edit, 180, scrollable: detailsScroll);
    await tester.pumpAndSettle();

    expect(tester.getSize(edit).height, greaterThanOrEqualTo(48));
    expect(
      find.byKey(const ValueKey('match-details-delete')).hitTestable(),
      findsOneWidget,
    );
    expect(edit.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'history keeps Alessandro and Vincenzo readable in card and details',
    (tester) async {
      final fixture = historyDesignFixture(count: 1);
      fixture.database.players[0] = fixture.database.players[0].copyWith(
        name: 'Alessandro',
      );
      fixture.database.players[2] = fixture.database.players[2].copyWith(
        name: 'Vincenzo',
      );
      await _pumpHistory(tester, fixture, const Size(320, 568), textScale: 2);
      addTearDown(fixture.dispose);

      final teamText = find.text('Alessandro / Vincenzo');
      expect(teamText, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(teamText).didExceedMaxLines,
        isFalse,
      );

      final match = find.byKey(const ValueKey('history-match-history-0'));
      final historyScroll = find.byKey(const ValueKey('history-scroll'));
      await tester.drag(historyScroll, const Offset(0, -320));
      await tester.pumpAndSettle();
      await tester.ensureVisible(match);
      await tester.tap(match);
      await tester.pumpAndSettle();

      final detailsTeam = find.text('Alessandro / Vincenzo  4');
      expect(detailsTeam, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(detailsTeam).didExceedMaxLines,
        isFalse,
      );

      final detailsScroll = find.byType(Scrollable).last;
      final edit = find.byKey(const ValueKey('match-details-edit'));
      await tester.scrollUntilVisible(edit, 180, scrollable: detailsScroll);
      await tester.pumpAndSettle();
      expect(edit.hitTestable(), findsOneWidget);
      expect(
        find.byKey(const ValueKey('match-details-delete')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpHistory(
  WidgetTester tester,
  DesignFixture fixture,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = size.width > size.height
      ? const FakeViewPadding(left: 44, right: 44, bottom: 24)
      : const FakeViewPadding(top: 62, bottom: 34);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await fixture.load();
  await fixture.styleRepository.save(AppStyle.italia90);
  await tester.pumpWidget(
    HistoryClockScope(now: () => DateTime(2026, 1, 8), child: fixture.app),
  );
  await tester.pumpAndSettle();
  openHistory(tester.element(find.byType(HomeScreen)));
  await tester.pumpAndSettle();
}
