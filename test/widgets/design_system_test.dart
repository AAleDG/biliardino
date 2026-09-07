import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/avatar.dart';
import 'package:biliardino/widgets/design/brand_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Selected filter chips keep labels legible and toggle normally', (
    tester,
  ) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.southAfrica(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FilterChip(
              label: const Text('Solo presenti'),
              selected: selected,
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Solo presenti'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    final label = tester
        .widget<RichText>(
          find
              .descendant(
                of: find.byType(FilterChip),
                matching: find.byType(RichText),
              )
              .first,
        )
        .text
        .style!
        .color!;
    final foreground = label.computeLuminance();
    final background = AppColors.primary.computeLuminance();
    expect((foreground + .05) / (background + .05), greaterThanOrEqualTo(4.5));
    await tester.tap(find.text('Solo presenti'));
    await tester.pumpAndSettle();
    expect(selected, isFalse);
  });

  testWidgets('Shared controls remain operable at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.southAfrica(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: Builder(
              builder: (context) => Scaffold(
                appBar: brandAppBar(context, title: 'GIOCATORI'),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const PlayerAvatar(name: 'Èlia'),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        errorText: 'Controlla il nome.',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => taps++,
                      child: const Text('Aggiungi'),
                    ),
                    const ElevatedButton(onPressed: null, child: Text('Salva')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Aggiungi'));
    await tester.tap(find.text('Aggiungi'));
    expect(taps, 1);
    expect(
      tester.getSize(find.widgetWithText(ElevatedButton, 'Aggiungi')).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Platform reduced motion changes notify a running visual owner', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _MotionProbe()));
    expect(find.text('Moving'), findsOneWidget);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.text('Settled'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}

class _MotionProbe extends StatefulWidget {
  const _MotionProbe();
  @override
  State<_MotionProbe> createState() => _MotionProbeState();
}

class _MotionProbeState extends State<_MotionProbe> with MotionAwareState {
  bool settled = false;
  @override
  void settleMotion() {
    settled = true;
  }

  @override
  Widget build(BuildContext context) => Text(settled ? 'Settled' : 'Moving');
}
