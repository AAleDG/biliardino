import 'dart:async';
import 'package:biliardino/screens/match_editor/match_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';
import '../support/match_editor_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  for (final details in [false, true]) {
    testWidgets(
      'entry details=$details saves exact match once and returns to history',
      (tester) async {
        final fixture = await pumpDistinta(tester, details: details);
        final before = fixture.matchesRepository.matches.single.toMap();
        expect(find.text('Altre opzioni'), findsNothing);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        await editorTap(tester, find.byKey(const ValueKey('edit-match-save')));
        expect(find.byType(MatchEditorScreen), findsNothing);
        expect(fixture.database.updateMatchCalls, 1);
        expect(fixture.matchesRepository.matches.single.toMap(), before);
      },
    );
  }
  testWidgets(
    'scorer reassignment keeps score and publishes through repository',
    (tester) async {
      final fixture = await pumpDistinta(tester);
      await editorTap(
        tester,
        find.byTooltip('Diminuisci Gol di Andrea, squadra 1'),
      );
      expect(find.text('3 / 4 gol assegnati · Mancano 1'), findsOneWidget);
      await editorTap(tester, find.byTooltip('Aumenta Gol di Luca, squadra 1'));
      await editorTap(tester, find.byKey(const ValueKey('edit-match-save')));
      final match = fixture.matchesRepository.matches.single;
      expect(match.t1Score, 4);
      expect(match.goalsByPlayer('p0'), 3);
      expect(match.goalsByPlayer('p2'), 1);
    },
  );
  testWidgets('dirty cancel keeps draft or discards without writing', (
    tester,
  ) async {
    final fixture = await pumpDistinta(tester);
    await editorTap(tester, find.byTooltip('Aumenta Punteggio squadra 1'));
    await editorTap(tester, find.text('Annulla'));
    expect(find.text('Scartare le modifiche?'), findsOneWidget);
    await editorTap(tester, find.text('Continua a modificare'));
    expect(find.byType(MatchEditorScreen), findsOneWidget);
    await editorTap(tester, find.text('Annulla'));
    await editorTap(tester, find.text('Scarta'));
    expect(find.byType(MatchEditorScreen), findsNothing);
    expect(fixture.database.updateMatchCalls, 0);
  });
  testWidgets(
    'single scorer requires explicit confirmation, no one-choice menus',
    (tester) async {
      final fixture = await pumpDistinta(tester, legacy: true);
      await editorTap(tester, find.byKey(const ValueKey('edit-match-save')));
      expect(fixture.database.updateMatchCalls, 0);
      expect(
        find.text('Assegna tutti i marcatori prima di salvare.'),
        findsOneWidget,
      );
      for (final team in [1, 2]) {
        await editorTap(
          tester,
          find.byKey(ValueKey('edit-confirm-scorer-$team')),
        );
      }
      await editorTap(tester, find.byKey(const ValueKey('edit-match-save')));
      expect(fixture.matchesRepository.matches.single.scorerIds.length, 9);
    },
  );
  testWidgets(
    'roster filters occupied players and search, replacement keeps missing explicit',
    (tester) async {
      await pumpDistinta(tester);
      await editorTap(tester, find.byKey(const ValueKey('edit-player-1-0')));
      expect(find.byKey(const ValueKey('edit-pick-p3')), findsNothing);
      expect(find.byKey(const ValueKey('edit-pick-p1')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('edit-roster-search')),
        'Sara',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit-pick-p1')), findsNothing);
      await editorTap(tester, find.byKey(const ValueKey('edit-pick-p5')));
      await editorTap(tester, find.text('Sostituisci'));
      expect(find.text('0 / 4 gol assegnati · Mancano 4'), findsOneWidget);
      expect(find.text('Sara'), findsOneWidget);
    },
  );
  testWidgets('date and time pickers cancel without modifying the match', (
    tester,
  ) async {
    final fixture = await pumpDistinta(tester);
    final original = fixture.matchesRepository.matches.single.playedAt;
    await editorTap(tester, find.byKey(const ValueKey('edit-date')));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    Navigator.of(tester.element(find.byType(DatePickerDialog))).pop();
    await tester.pumpAndSettle();
    await editorTap(tester, find.byKey(const ValueKey('edit-time')));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(
      tester
          .widget<TimePickerDialog>(find.byType(TimePickerDialog))
          .initialEntryMode,
      TimePickerEntryMode.inputOnly,
    );
    expect(find.byIcon(Icons.access_time), findsNothing);
    Navigator.of(tester.element(find.byType(TimePickerDialog))).pop();
    await tester.pumpAndSettle();
    await editorTap(tester, find.byKey(const ValueKey('edit-match-save')));
    expect(fixture.matchesRepository.matches.single.playedAt, original);
  });
  testWidgets('accepted pickers preserve untouched values and scorer records', (
    tester,
  ) async {
    final fixture = await pumpDistinta(tester);
    final before = fixture.matchesRepository.matches.single;
    await editorTap(tester, find.byKey(const ValueKey('edit-date')));
    Navigator.of(
      tester.element(find.byType(DatePickerDialog)),
    ).pop(DateTime(2026, 2, 9));
    await tester.pumpAndSettle();
    expect(find.text('13:30'), findsOneWidget);
    await editorTap(tester, find.byKey(const ValueKey('edit-time')));
    Navigator.of(
      tester.element(find.byType(TimePickerDialog)),
    ).pop(const TimeOfDay(hour: 16, minute: 45));
    await tester.pumpAndSettle();
    expect(find.text('09/02/2026'), findsOneWidget);
    await editorTap(tester, find.byKey(const ValueKey('edit-match-save')));
    final after = fixture.matchesRepository.matches.single;
    expect(after.playedAt, DateTime(2026, 2, 9, 16, 45));
    expect(after.scorerIds, before.scorerIds);
    expect(after.t1Score, before.t1Score);
  });
  testWidgets('keyboard insets keep numeric and roster controls reachable', (
    tester,
  ) async {
    await pumpDistinta(tester, size: const Size(320, 568), scale: 2);
    await editorTap(tester, find.byKey(const ValueKey('edit-score-1')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('edit-score-input')),
      '12',
    );
    await editorTap(tester, find.text('Conferma'));
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    await editorTap(tester, find.byKey(const ValueKey('edit-player-1-0')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('edit-roster-search')),
      'Sara',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await editorTap(tester, find.byKey(const ValueKey('edit-pick-p5')));
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    expect(find.text('Sostituire il giocatore?'), findsOneWidget);
  });
  testWidgets(
    'failed pending save disables duplicates and retains draft for retry',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await pumpDistinta(
        tester,
        onSave: (_) {
          calls++;
          return calls == 1 ? pending.future : Future.value();
        },
      );
      final save = find.byKey(const ValueKey('edit-match-save'));
      await tester.tap(save);
      await tester.pump();
      await tester.tap(save);
      await tester.pump();
      expect(calls, 1);
      pending.completeError(StateError('test write failed'));
      await tester.pumpAndSettle();
      expect(
        find.text('Impossibile modificare la partita. Riprova.'),
        findsOneWidget,
      );
      expect(find.byType(MatchEditorScreen), findsOneWidget);
      await editorTap(tester, save);
      expect(calls, 2);
      expect(find.byType(MatchEditorScreen), findsNothing);
    },
  );
  testWidgets('late save completion after disposal has no stale navigation', (
    tester,
  ) async {
    final pending = Completer<void>();
    await pumpDistinta(tester, onSave: (_) => pending.future);
    await tester.tap(find.byKey(const ValueKey('edit-match-save')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final viewport in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets(
      'large text names, numeric correction, targets and semantics at $viewport',
      (tester) async {
        await pumpDistinta(tester, size: viewport, scale: 2, longNames: true);
        final semantics = tester.ensureSemantics();
        try {
          final date = find.byKey(const ValueKey('edit-date'));
          expect(
            tester
                .getSemantics(date)
                .getSemanticsData()
                .hasAction(SemanticsAction.tap),
            isTrue,
          );
          final target = find.byTooltip('Aumenta Punteggio squadra 2');
          await editorTap(tester, target);
          expect(tester.getSize(target).shortestSide, greaterThanOrEqualTo(48));
          final value = find.byKey(const ValueKey('edit-score-2'));
          await editorTap(tester, value);
          await tester.enterText(
            find.byKey(const ValueKey('edit-score-input')),
            '12345',
          );
          await editorTap(tester, find.text('Conferma'));
          await editorTap(
            tester,
            find.byKey(const ValueKey('edit-match-save')),
          );
          expect(
            find.byKey(const ValueKey('edit-match-error')).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
