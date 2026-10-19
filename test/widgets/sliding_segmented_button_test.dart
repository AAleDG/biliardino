import 'dart:ui' as ui;

import 'package:biliardino/widgets/sliding_segmented_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final override in [true, false]) {
    testWidgets(
      'Segment colors use ${override ? 'screen overrides' : 'theme defaults'} and inherit unspecified typography',
      (tester) async {
        final capture = GlobalKey();
        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              segmentedButtonTheme: SegmentedButtonThemeData(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.red
                        : Colors.white,
                  ),
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: capture,
                  child: SizedBox(
                    width: 320,
                    child: StatefulBuilder(
                      builder: (context, setState) =>
                          SlidingSegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('One')),
                              ButtonSegment(value: 1, label: Text('Two')),
                            ],
                            selected: {selected},
                            showSelectedIcon: false,
                            expandedInsets: EdgeInsets.zero,
                            style: override
                                ? ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.resolveWith(
                                          (states) =>
                                              states.contains(
                                                WidgetState.selected,
                                              )
                                              ? Colors.blue
                                              : Colors.white,
                                        ),
                                  )
                                : null,
                            onSelectionChanged: (values) =>
                                setState(() => selected = values.single),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Future<void> expectSelectedFill(double x) async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final actual = await tester.runAsync(() async {
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              );
              final pixel = ((image.height ~/ 2) * image.width + x.toInt()) * 4;
              return Color.fromARGB(
                bytes!.getUint8(pixel + 3),
                bytes.getUint8(pixel),
                bytes.getUint8(pixel + 1),
                bytes.getUint8(pixel + 2),
              );
            } finally {
              image.dispose();
            }
          });
          expect(
            actual!.toARGB32(),
            (override ? Colors.blue : Colors.red).toARGB32(),
          );
        }

        await expectSelectedFill(16);
        final label = tester.widget<RichText>(
          find.descendant(
            of: find.text('One'),
            matching: find.byType(RichText),
          ),
        );
        expect(label.text.style!.fontSize, 22);

        await tester.tap(find.text('Two'));
        await tester.pumpAndSettle();
        expect(selected, 1);
        await expectSelectedFill(304);
      },
    );
  }
}
