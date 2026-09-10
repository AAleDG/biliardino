import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The approved South Africa ribbon treatment for branded custom sheets.
///
/// Keep this decorative layer at the top edge of the sheet, behind the drag
/// handle and content. Native/system sheets and destructive confirmations do
/// not adopt it automatically.
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
      AppColors.primary,
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
      AppColors.yellow,
      Path()
        ..moveTo(-8, -6)
        ..lineTo(204, -6)
        ..cubicTo(162, 0, 88, 10, -8, 10)
        ..close(),
    );
    _drawRibbon(
      canvas,
      AppColors.teamTwo,
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
