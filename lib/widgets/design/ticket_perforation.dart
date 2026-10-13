import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Shared dashed rule for the action and ranking tickets.
class TicketPerforation extends CustomPainter {
  const TicketPerforation();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;
    for (double y = 0; y + 3 <= size.height; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant TicketPerforation oldDelegate) => false;
}
