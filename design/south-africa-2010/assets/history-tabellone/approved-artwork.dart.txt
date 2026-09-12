import 'package:flutter/material.dart';
import 'package:biliardino/theme/design_tokens.dart';

enum HistoryRibbon { header, card, footer }

/// Decorative candidate; no match information or interaction is painted.
class HistoryRibbonPainter extends CustomPainter {
  const HistoryRibbonPainter(this.ribbon);
  final HistoryRibbon ribbon;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 402, size.height / 100);
    switch (ribbon) {
      case HistoryRibbon.header:
        _header(canvas);
      case HistoryRibbon.card:
        _card(canvas);
      case HistoryRibbon.footer:
        _footer(canvas);
    }
    canvas.restore();
  }

  void _header(Canvas canvas) {
    _fill(
      canvas,
      Path()
        ..moveTo(0, 6)
        ..cubicTo(105, 77, 253, 55, 402, 3)
        ..lineTo(402, 23)
        ..cubicTo(255, 71, 105, 90, 0, 30)
        ..close(),
      AppColors.yellow,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(0, 40)
        ..cubicTo(107, 99, 261, 76, 402, 32)
        ..lineTo(402, 48)
        ..cubicTo(252, 94, 115, 122, 0, 66)
        ..close(),
      AppColors.success,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(157, 91)
        ..cubicTo(248, 81, 324, 66, 402, 55)
        ..lineTo(402, 70)
        ..cubicTo(304, 87, 230, 99, 157, 91)
        ..close(),
      AppColors.primary,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(257, 99)
        ..cubicTo(325, 87, 367, 80, 402, 78)
        ..lineTo(402, 89)
        ..cubicTo(347, 93, 310, 101, 257, 99)
        ..close(),
      AppColors.error,
    );
  }

  void _card(Canvas canvas) {
    _fill(
      canvas,
      Path()
        ..moveTo(0, 5)
        ..cubicTo(70, 38, 151, 63, 190, 100)
        ..cubicTo(119, 74, 60, 60, 0, 38)
        ..close(),
      AppColors.primary,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(0, 49)
        ..cubicTo(73, 72, 137, 88, 190, 100)
        ..lineTo(0, 100)
        ..close(),
      AppColors.success,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(65, 19)
        ..cubicTo(123, 36, 175, 69, 198, 100)
        ..cubicTo(159, 65, 118, 46, 65, 19)
        ..close(),
      AppColors.yellow,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(402, 0)
        ..cubicTo(329, 32, 258, 73, 217, 100)
        ..cubicTo(287, 79, 344, 56, 402, 36)
        ..close(),
      AppColors.error,
      reverse: true,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(402, 48)
        ..cubicTo(333, 72, 267, 91, 217, 100)
        ..lineTo(402, 100)
        ..close(),
      AppColors.yellow,
      reverse: true,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(337, 17)
        ..cubicTo(290, 28, 238, 62, 207, 100)
        ..cubicTo(252, 68, 285, 49, 337, 17)
        ..close(),
      AppColors.yellow,
      reverse: true,
    );
  }

  void _footer(Canvas canvas) {
    // Rear blue/red sweeps sit behind the broad yellow/green foreground.
    _fill(
      canvas,
      Path()
        ..moveTo(185, 38)
        ..cubicTo(271, 36, 346, 23, 402, 0)
        ..lineTo(402, 46)
        ..cubicTo(338, 29, 258, 41, 185, 38)
        ..close(),
      AppColors.primary,
      reverse: true,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(233, 48)
        ..cubicTo(302, 30, 367, 38, 402, 58)
        ..lineTo(402, 100)
        ..lineTo(363, 100)
        ..cubicTo(335, 72, 289, 55, 233, 48)
        ..close(),
      AppColors.error,
      reverse: true,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(0, 5)
        ..cubicTo(91, 49, 283, 45, 362, 100)
        ..lineTo(329, 100)
        ..cubicTo(250, 64, 91, 64, 0, 32)
        ..close(),
      AppColors.yellow,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(0, 39)
        ..cubicTo(96, 73, 231, 64, 314, 100)
        ..lineTo(221, 100)
        ..cubicTo(144, 84, 55, 88, 0, 65)
        ..close(),
      AppColors.success,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(0, 88)
        ..cubicTo(68, 74, 135, 95, 173, 100)
        ..lineTo(0, 100)
        ..close(),
      AppColors.error,
    );
  }

  void _fill(Canvas canvas, Path path, Color color, {bool reverse = false}) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: reverse ? Alignment.bottomRight : Alignment.bottomLeft,
          end: reverse ? Alignment.topLeft : Alignment.topRight,
          colors: [
            Color.lerp(
              color,
              color == AppColors.yellow ? AppColors.teamTwo : AppColors.ink,
              .12,
            )!,
            color,
            Color.lerp(color, AppColors.surface, .14)!,
            color,
          ],
          stops: const [0, .36, .7, 1],
        ).createShader(path.getBounds()),
    );
  }

  @override
  bool shouldRepaint(HistoryRibbonPainter oldDelegate) =>
      ribbon != oldDelegate.ribbon;
}

class HistoryRibbonArtwork extends StatelessWidget {
  const HistoryRibbonArtwork(this.ribbon, {super.key, required this.height});
  final HistoryRibbon ribbon;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(painter: HistoryRibbonPainter(ribbon)),
      ),
    ),
  );
}
