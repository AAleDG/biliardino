import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Review candidate: only the ticket's yellow stub and lower ribbon sweeps.
/// Labels, avatars, badges and perforation remain separate live components.
class RankingAwardTicketArtwork extends CustomPainter {
  const RankingAwardTicketArtwork({required this.identityWidth});
  final double identityWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stub = Rect.fromLTWH(0, 0, identityWidth, size.height);
    canvas.drawRect(
      stub,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.yellow,
            Color.lerp(AppColors.yellow, AppColors.surface, .25)!,
            AppColors.yellow,
          ],
        ).createShader(stub),
    );
    canvas.save();
    canvas.clipRect(stub);
    canvas.translate(0, size.height - 44);
    canvas.scale(identityWidth / 100, 1);
    _band(canvas, 0, 14, AppColors.success);
    _band(canvas, 14, 17, AppColors.surface);
    _band(canvas, 17, 28, AppColors.ink);
    _band(canvas, 28, 44, AppColors.error);
    canvas.restore();

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        identityWidth + 1,
        0,
        size.width - identityWidth - 1,
        size.height,
      ),
    );
    canvas.translate(identityWidth + 1, size.height - 28);
    canvas.scale((size.width - identityWidth - 1) / 100, 1);
    final blue = Path()
      ..moveTo(0, 22)
      ..cubicTo(35, 22, 72, 16, 100, 0)
      ..lineTo(100, 10)
      ..cubicTo(70, 25, 30, 30, 0, 30)
      ..close();
    final green = Path()
      ..moveTo(0, 34)
      ..cubicTo(35, 32, 72, 26, 100, 14)
      ..lineTo(100, 30)
      ..lineTo(0, 42)
      ..close();
    canvas.drawPath(blue, Paint()..color = AppColors.primary);
    canvas.drawPath(green, Paint()..color = AppColors.success);
    canvas.restore();
  }

  void _band(Canvas canvas, double start, double end, Color color) {
    final path = Path()
      ..moveTo(0, start)
      ..cubicTo(25, start + 7, 65, start + 14, 100, start + 15)
      ..lineTo(100, end + 15)
      ..cubicTo(65, end + 14, 25, end + 7, 0, end)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant RankingAwardTicketArtwork oldDelegate) =>
      identityWidth != oldDelegate.identityWidth;
}
