import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Live-match illustration colors; ordinary orange controls retain ink text.
abstract final class LiveMatchPaints {
  static const orangeTextSurface = Color(0xFFD94500);
  static const blue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0086F5), AppColors.teamOne, Color(0xFF003B80)],
    stops: [0, .48, 1],
  );
  static const orange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFAA00), Color(0xFFEF4B00), Color(0xFFEF290D)],
    stops: [0, .32, 1],
  );
  static const orangeHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEB6500), Color(0xFFD44800), Color(0xFFAF290A)],
    stops: [0, .48, 1],
  );
  static const yellow = LinearGradient(
    colors: [Color(0xFFFFE36A), AppColors.yellow, Color(0xFFFFAE00)],
  );
  static const green = LinearGradient(
    colors: [Color(0xFF009E50), AppColors.success, Color(0xFF00582B)],
  );
  static const red = LinearGradient(
    colors: [Color(0xFFFF4B16), Color(0xFFE71922), Color(0xFFA9101C)],
  );
  static const goldOrange = LinearGradient(
    colors: [Color(0xFFFFC000), AppColors.teamTwo, Color(0xFFF04413)],
  );
  static const dark = LinearGradient(
    colors: [Color(0xFF273338), AppColors.ink, Color(0xFF080C10)],
  );
}

void _fill(Canvas canvas, Path path, Gradient gradient) {
  canvas.drawPath(
    path,
    Paint()..shader = gradient.createShader(path.getBounds()),
  );
}

/// Rounded score fields and tapered, cream-separated ribbons beneath them.
class LiveFieldPainter extends CustomPainter {
  const LiveFieldPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 440, size.height / 310);
    // Accents sit outside the field clip, so their fine tips remain visible.
    _fill(
      canvas,
      Path()
        ..moveTo(0, 238)
        ..cubicTo(28, 272, 62, 298, 111, 309)
        ..cubicTo(61, 302, 21, 283, 0, 264)
        ..close(),
      LiveMatchPaints.yellow,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(0, 272)
        ..cubicTo(24, 290, 49, 302, 96, 310)
        ..cubicTo(55, 311, 19, 300, 0, 291)
        ..close(),
      LiveMatchPaints.blue,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(440, 239)
        ..lineTo(440, 261)
        ..cubicTo(415, 284, 379, 301, 329, 309)
        ..cubicTo(373, 293, 413, 269, 440, 239)
        ..close(),
      LiveMatchPaints.goldOrange,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(440, 268)
        ..lineTo(440, 285)
        ..cubicTo(416, 298, 387, 307, 353, 310)
        ..cubicTo(388, 299, 418, 285, 440, 268)
        ..close(),
      LiveMatchPaints.green,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(440, 289)
        ..lineTo(440, 298)
        ..cubicTo(424, 305, 407, 310, 389, 310)
        ..cubicTo(409, 304, 426, 297, 440, 289)
        ..close(),
      LiveMatchPaints.blue,
    );
    // Shoulders continue offscreen instead of forming contained rounded corners.
    final silhouette = Path()
      ..moveTo(-60, 148.378)
      ..cubicTo(-24, 75.009, 72, 64, 122, 74)
      ..cubicTo(160, 80, 184, 86, 218, 94)
      ..cubicTo(256, 86, 280, 80, 318, 74)
      ..cubicTo(368, 64, 464, 75.009, 500, 148.378)
      ..lineTo(500, 232)
      ..lineTo(440, 232)
      ..cubicTo(403, 284, 348, 307, 246, 307)
      ..lineTo(194, 307)
      ..cubicTo(100, 307, 35, 284, 0, 232)
      ..lineTo(-60, 232)
      ..close();
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 440, 310));
    canvas.clipPath(silhouette);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 440, 310),
      Paint()
        ..shader = LiveMatchPaints.blue.createShader(
          const Rect.fromLTWH(0, 60, 220, 250),
        ),
    );
    final orange = Path()
      ..moveTo(220, 0)
      ..lineTo(440, 0)
      ..lineTo(440, 310)
      ..lineTo(225, 310)
      ..cubicTo(243, 237, 238, 167, 220, 110)
      ..close();
    canvas.drawPath(
      orange,
      Paint()
        ..shader = LiveMatchPaints.orange.createShader(
          const Rect.fromLTWH(220, 60, 220, 250),
        ),
    );
    _fill(
      canvas,
      Path()
        ..moveTo(204, 78)
        ..lineTo(230, 78)
        ..cubicTo(243, 157, 259, 227, 232, 310)
        ..lineTo(196, 310)
        ..cubicTo(201, 220, 187, 141, 204, 78)
        ..close(),
      LiveMatchPaints.dark,
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(LiveFieldPainter oldDelegate) => false;
}

class LiveEdgeRibbonPainter extends CustomPainter {
  const LiveEdgeRibbonPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 440, 1);
    void fill(Path path, Gradient gradient) => _fill(canvas, path, gradient);
    fill(
      Path()
        ..moveTo(0, 0)
        ..lineTo(190, 0)
        ..cubicTo(125, 47, 47, 103, 0, 179)
        ..close(),
      LiveMatchPaints.yellow,
    );
    fill(
      Path()
        ..moveTo(242, 0)
        ..lineTo(440, 0)
        ..lineTo(440, 171)
        ..cubicTo(411, 111, 338, 65, 242, 0)
        ..close(),
      LiveMatchPaints.yellow,
    );
    fill(
      Path()
        ..moveTo(0, 214)
        ..cubicTo(22, 163, 42, 123, 77, 96)
        ..cubicTo(40, 111, 12, 142, 0, 167)
        ..close(),
      LiveMatchPaints.blue,
    );
    fill(
      Path()
        ..moveTo(440, 192)
        ..cubicTo(421, 159, 411, 140, 384, 117)
        ..cubicTo(421, 138, 434, 157, 440, 166)
        ..close(),
      LiveMatchPaints.green,
    );
    // Footer paths are anchored to the body, which ends above navigation.
    final h = size.height;
    fill(
      Path()
        ..moveTo(0, h - 175)
        ..cubicTo(31, h - 94, 71, h - 37, 184, h)
        ..lineTo(117, h)
        ..cubicTo(38, h - 43, 18, h - 88, 0, h - 114)
        ..close(),
      LiveMatchPaints.green,
    );
    fill(
      Path()
        ..moveTo(0, h - 110)
        ..cubicTo(49, h - 44, 117, h - 8, 220, h)
        ..lineTo(110, h)
        ..cubicTo(49, h - 16, 16, h - 47, 0, h - 72)
        ..close(),
      LiveMatchPaints.yellow,
    );
    fill(
      Path()
        ..moveTo(0, h - 64)
        ..cubicTo(25, h - 31, 59, h - 12, 105, h)
        ..lineTo(52, h)
        ..cubicTo(26, h - 8, 9, h - 24, 0, h - 37)
        ..close(),
      LiveMatchPaints.dark,
    );
    fill(
      Path()
        ..moveTo(440, h - 185)
        ..lineTo(440, h - 125)
        ..cubicTo(409, h - 70, 370, h - 39, 324, h - 14)
        ..lineTo(293, h - 12)
        ..cubicTo(360, h - 63, 398, h - 109, 440, h - 185)
        ..close(),
      LiveMatchPaints.yellow,
    );
    fill(
      Path()
        ..moveTo(440, h - 91)
        ..lineTo(440, h - 49)
        ..cubicTo(401, h - 34, 347, h - 32, 294, h - 37)
        ..cubicTo(359, h - 38, 411, h - 56, 440, h - 91)
        ..close(),
      LiveMatchPaints.red,
    );
    fill(
      Path()
        ..moveTo(440, h - 42)
        ..lineTo(440, h - 23)
        ..cubicTo(393, h - 22, 349, h - 28, 286, h - 33)
        ..cubicTo(352, h - 30, 406, h - 31, 440, h - 42)
        ..close(),
      LiveMatchPaints.goldOrange,
    );
    fill(
      Path()
        ..moveTo(77, h - 34)
        ..cubicTo(174, h - 5, 296, h - 24, 440, h - 15)
        ..lineTo(440, h)
        ..lineTo(198, h)
        ..cubicTo(143, h - 6, 108, h - 17, 77, h - 34)
        ..close(),
      LiveMatchPaints.blue,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(LiveEdgeRibbonPainter oldDelegate) => false;
}
