import 'package:flutter/material.dart';

import '../../theme/italia90_tokens.dart';

/// Lightweight Italia ’90 accent for custom editor sheets.
///
/// The shallow wave keeps the sheet hierarchy readable while preserving the
/// tricolour energy of the board around the top edge.
class SheetRibbonAccent extends StatelessWidget {
  const SheetRibbonAccent({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: ValueKey('sheet-ribbon-accent'),
          painter: _SheetRibbonAccentPainter(),
        ),
      ),
    ),
  );
}

class _SheetRibbonAccentPainter extends CustomPainter {
  const _SheetRibbonAccentPainter();

  static const _sourceSize = Size(440, 64);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / _sourceSize.width,
      size.height / _sourceSize.height,
    );

    _drawRibbon(
      canvas,
      Italia90.primary,
      Path()
        ..moveTo(-8, -6)
        ..lineTo(448, -6)
        ..lineTo(448, 16)
        ..cubicTo(354, 16, 282, 3, 220, 3)
        ..cubicTo(158, 3, 86, 16, -8, 16)
        ..close(),
    );
    _drawRibbon(
      canvas,
      Italia90.green,
      Path()
        ..moveTo(-8, -6)
        ..lineTo(204, -6)
        ..cubicTo(162, 0, 88, 10, -8, 10)
        ..close(),
    );
    _drawRibbon(
      canvas,
      Italia90.red,
      Path()
        ..moveTo(448, -6)
        ..lineTo(298, -6)
        ..cubicTo(338, 0, 390, 10, 448, 10)
        ..close(),
    );

    canvas.restore();
  }

  static void _drawRibbon(Canvas canvas, Color color, Path path) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SheetRibbonAccentPainter oldDelegate) => false;
}
