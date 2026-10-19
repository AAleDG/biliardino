import '../support/tab_transition_goldens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';
import '../support/match_editor_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  for (final scene in [
    ('reference', const Size(402, 874), 1.0, false, false),
    ('legacy', const Size(402, 874), 1.0, true, false),
    ('compact', const Size(320, 568), 2.0, false, true),
    ('landscape', const Size(568, 320), 2.0, false, true),
  ]) {
    testWidgets('Distinta real fonts ${scene.$1}', (tester) async {
      await pumpDistinta(
        tester,
        size: scene.$2,
        scale: scene.$3,
        legacy: scene.$4,
        longNames: scene.$5,
      );
      await expectLater(
        find.byKey(const ValueKey('editor-capture')),
        matchesGoldenFile(
          tabTransitionGolden('south-africa-distinta-${scene.$1}.png'),
        ),
      );
      if (scene.$5) {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('edit-total-2')),
          180,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('edit-match-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('editor-capture')),
          matchesGoldenFile(
            tabTransitionGolden(
              'south-africa-distinta-${scene.$1}-scrolled.png',
            ),
          ),
        );
      }
      if (scene.$1 == 'reference') {
        await editorTap(
          tester,
          find.byTooltip('Diminuisci Punteggio squadra 1'),
        );
        await expectLater(
          find.byKey(const ValueKey('editor-capture')),
          matchesGoldenFile(
            tabTransitionGolden('south-africa-distinta-mismatch.png'),
          ),
        );
      }
    });
  }
}
