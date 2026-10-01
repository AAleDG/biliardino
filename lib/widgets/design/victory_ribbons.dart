import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// One entrance, then a still frame around the result. Decorative only.
class VictoryRibbons extends CustomPainter {
  VictoryRibbons(this.animation, {required this.compact})
    : super(repaint: animation);

  final Animation<double> animation;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final arrival = Curves.easeOutCubic.transform((t / .48).clamp(0.0, 1.0));
    final retreat = Curves.easeInOutCubic.transform(
      ((t - .32) / .68).clamp(0.0, 1.0),
    );
    final depth = compact ? 24.0 : (size.height * .23).clamp(64.0, 220.0);
    final reach =
        (compact ? 12.0 : size.height * .13) * arrival * (1 - retreat);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.save();
    canvas.translate(-size.width * 1.15 * (1 - arrival), reach);
    canvas.scale(size.width / 1000, depth / 240);
    _sweep(canvas);
    canvas.restore();

    canvas.translate(size.width * (2.15 - 1.15 * arrival), size.height - reach);
    canvas.scale(-size.width / 1000, -depth / 240);
    _sweep(canvas);
    canvas.restore();
  }

  void _sweep(Canvas canvas) {
    _fill(
      canvas,
      Path()
        ..moveTo(-100, -400)
        ..lineTo(1100, -400)
        ..lineTo(1100, -30)
        ..cubicTo(770, -45, 660, 220, -100, 78)
        ..close(),
      AppColors.yellow,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(-100, 94)
        ..cubicTo(510, 245, 760, -20, 1100, -10)
        ..lineTo(1100, 36)
        ..cubicTo(730, 3, 430, 304, -100, 148)
        ..close(),
      AppColors.success,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(-100, 167)
        ..cubicTo(460, 297, 740, 40, 1100, 58)
        ..lineTo(1100, 108)
        ..cubicTo(740, 73, 395, 344, -100, 208)
        ..close(),
      AppColors.primary,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(290, 247)
        ..cubicTo(580, 209, 809, 105, 1100, 127)
        ..lineTo(1100, 150)
        ..cubicTo(806, 114, 625, 238, 290, 247)
        ..close(),
      AppColors.error,
    );
  }

  void _fill(Canvas canvas, Path path, Color color) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(60, 160),
          const Offset(880, 0),
          [color, Color.lerp(color, Colors.white, .17)!, color],
          const [0, .5, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(VictoryRibbons oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.compact != compact;
}
