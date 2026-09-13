import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/design/pass_ticket.dart';

void main() {
  testWidgets('one semantic button and enabled/disabled action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    var taps = 0;
    Future<void> pump(bool enabled) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.southAfrica(),
        home: Scaffold(
          body: PassTicket(
            title: 'Crea backup',
            subtitle: 'Giocatori e partite',
            format: 'JSON',
            icon: Icons.note_outlined,
            trailing: Icons.ios_share,
            onTap: enabled
                ? () {
                    taps++;
                  }
                : null,
          ),
        ),
      ),
    );
    await pump(true);
    final node = tester.getSemantics(find.byType(PassTicket));
    expect(
      node,
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        label: 'Crea backup\nJSON\nGiocatori e partite',
      ),
    );
    await tester.tap(find.text('Crea backup'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    await pump(false);
    await tester.tap(find.text('Crea backup'));
    expect(taps, 1);
    semantics.dispose();
  });
}
