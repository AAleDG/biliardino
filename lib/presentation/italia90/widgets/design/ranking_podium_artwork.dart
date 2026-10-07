import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/italia90_tokens.dart';

/// Decorative foosball figure used inside a podium card.
///
/// It is painted as a small geometric mark so the ranking keeps the board
/// language without introducing another screen asset.
class RankingFoosballFigure extends StatelessWidget {
  const RankingFoosballFigure({
    super.key,
    required this.shirtColor,
    this.compact = false,
  });

  final Color shirtColor;
  final bool compact;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _FoosballFigurePainter(shirtColor: shirtColor, compact: compact),
    child: const SizedBox.expand(),
  );
}

class _FoosballFigurePainter extends CustomPainter {
  const _FoosballFigurePainter({
    required this.shirtColor,
    required this.compact,
  });

  final Color shirtColor;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const designSize = Size(120, 110);
    final unitScale = math.min(
      size.width / designSize.width,
      size.height / designSize.height,
    );
    final offset = Offset(
      (size.width - designSize.width * unitScale) / 2,
      (size.height - designSize.height * unitScale) / 2,
    );
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(unitScale, unitScale);

    final outline = Paint()
      ..color = Italia90.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;
    final rod = RRect.fromRectAndRadius(
      const Rect.fromLTRB(1, 49, 119, 60),
      const Radius.circular(5),
    );
    canvas.drawRRect(rod, Paint()..color = Italia90.ink);
    canvas.drawLine(
      const Offset(5, 51),
      const Offset(115, 51),
      Paint()
        ..color = const Color(0xFFBBC1C0)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      const Offset(5, 58),
      const Offset(115, 58),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1,
    );

    final body = Path()
      ..moveTo(44, 36)
      ..quadraticBezierTo(33, 38, 33, 49)
      ..lineTo(34, 73)
      ..lineTo(42, 78)
      ..lineTo(45, 98)
      ..lineTo(75, 98)
      ..lineTo(78, 78)
      ..lineTo(86, 73)
      ..lineTo(87, 49)
      ..quadraticBezierTo(87, 38, 76, 36)
      ..close();
    canvas.drawPath(body, Paint()..color = shirtColor);
    canvas.drawPath(body, outline);
    canvas.drawPath(
      Path()
        ..moveTo(42, 40)
        ..lineTo(38, 46)
        ..lineTo(39, 70),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawPath(
      Path()
        ..moveTo(79, 42)
        ..lineTo(82, 47)
        ..lineTo(81, 71),
      Paint()
        ..color = Italia90.ink.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawRect(
      const Rect.fromLTRB(44, 72, 76, 91),
      Paint()..color = const Color(0xFFF2F1E5),
    );
    canvas.drawRect(const Rect.fromLTRB(44, 72, 76, 91), outline);
    canvas.drawLine(const Offset(60, 76), const Offset(60, 91), outline);
    canvas.drawRect(
      const Rect.fromLTRB(46, 92, 74, 104),
      Paint()..color = shirtColor,
    );
    canvas.drawRect(const Rect.fromLTRB(46, 92, 74, 104), outline);
    canvas.drawLine(const Offset(60, 93), const Offset(60, 103), outline);

    final face = Path()
      ..moveTo(48, 16)
      ..lineTo(73, 16)
      ..lineTo(73, 30)
      ..lineTo(64, 44)
      ..lineTo(57, 44)
      ..lineTo(47, 31)
      ..close();
    canvas.drawOval(
      const Rect.fromLTRB(43, 3, 78, 39),
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      const Rect.fromLTRB(45, 5, 76, 37),
      Paint()..color = Italia90.ink,
    );
    canvas.drawPath(face, Paint()..color = const Color(0xFFFFCA7B));
    canvas.drawPath(
      Path()
        ..moveTo(64, 17)
        ..lineTo(73, 17)
        ..lineTo(73, 30)
        ..lineTo(64, 44)
        ..close(),
      Paint()..color = const Color(0xFFECA451),
    );
    canvas.drawPath(
      Path()
        ..moveTo(47, 27)
        ..lineTo(48, 15)
        ..quadraticBezierTo(59, 7, 73, 15)
        ..lineTo(73, 24)
        ..lineTo(68, 17)
        ..lineTo(53, 18)
        ..lineTo(51, 29)
        ..close(),
      Paint()..color = Italia90.ink,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FoosballFigurePainter oldDelegate) =>
      shirtColor != oldDelegate.shirtColor || compact != oldDelegate.compact;
}

/// Small recognition-strip texture that echoes the original Italia '90 board.
class RankingRecognitionArtwork extends CustomPainter {
  const RankingRecognitionArtwork();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 402, size.height / 78);

    for (var index = 0; index < 8; index++) {
      final horizontal = index * 57.0;
      _polygon(canvas, [
        Offset(horizontal, 0),
        Offset(horizontal + 35, 0),
        Offset(horizontal - 12, 18),
      ], Italia90.teamTwo);
      _polygon(canvas, [
        Offset(horizontal, 78),
        Offset(horizontal + 46, 78),
        Offset(horizontal + 25, 55),
      ], Italia90.teamTwo);
    }
    _polygon(canvas, const [
      Offset(0, 28),
      Offset(39, 43),
      Offset(0, 38),
    ], Italia90.teamTwo);
    _polygon(canvas, const [
      Offset(402, 22),
      Offset(365, 38),
      Offset(402, 34),
    ], Italia90.teamTwo);

    canvas.restore();
  }

  void _polygon(Canvas canvas, List<Offset> points, Color color) {
    canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant RankingRecognitionArtwork oldDelegate) => false;
}

/// Candidate Italia '90 impact artwork for explicit review previews.
///
/// Production podiums keep this disabled until the exact device rendering is
/// approved by the user.
class RankingPodiumArtwork extends CustomPainter {
  const RankingPodiumArtwork({this.foreground = false});

  final bool foreground;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 402, size.height / 342);

    if (foreground) {
      _drawGroundMarks(canvas);
    } else {
      _drawBurst(canvas);
      _drawCrownAndStars(canvas);
    }
    canvas.restore();
  }

  void _drawBurst(Canvas canvas) {
    const center = Offset(201, 218);
    final rays = <({double angle, double length, double width, Color color})>[
      (angle: -2.78, length: 204, width: 38, color: Italia90.teamOne),
      (angle: -2.38, length: 135, width: 22, color: Italia90.teamTwo),
      (angle: -2.08, length: 236, width: 35, color: Italia90.green),
      (angle: -1.82, length: 215, width: 45, color: Italia90.teamTwo),
      (angle: -1.42, length: 221, width: 46, color: Italia90.teamTwo),
      (angle: -1.16, length: 209, width: 32, color: Italia90.teamTwo),
      (angle: -.84, length: 254, width: 34, color: Italia90.green),
      (angle: -.53, length: 206, width: 34, color: Italia90.red),
      (angle: -.25, length: 171, width: 21, color: Italia90.teamOne),
      (angle: .15, length: 149, width: 17, color: Italia90.green),
      (angle: .48, length: 157, width: 25, color: Italia90.red),
      (angle: .78, length: 122, width: 16, color: Italia90.ink),
      (angle: 2.35, length: 151, width: 22, color: Italia90.green),
      (angle: 2.62, length: 132, width: 24, color: Italia90.red),
      (angle: 2.92, length: 174, width: 20, color: Italia90.teamOne),
    ];

    for (final ray in rays) {
      final direction = Offset(math.cos(ray.angle), math.sin(ray.angle));
      final perpendicular = Offset(-direction.dy, direction.dx);
      final start = center + direction * 42;
      final tip = center + direction * ray.length;
      _polygon(canvas, [
        start + perpendicular * (ray.width / 2),
        tip + perpendicular * 2,
        tip - perpendicular * 2,
        start - perpendicular * (ray.width / 2),
      ], ray.color);
      _polygon(canvas, [
        start + perpendicular * (ray.width / 2 + 3),
        tip + perpendicular * 5,
        tip + perpendicular * 2,
        start + perpendicular * (ray.width / 2),
      ], Colors.white);
    }
  }

  void _drawCrownAndStars(Canvas canvas) {
    _polygon(canvas, const [
      Offset(186, 30),
      Offset(180, 10),
      Offset(194, 22),
      Offset(201, 5),
      Offset(208, 22),
      Offset(223, 10),
      Offset(217, 30),
    ], Italia90.ink);
    for (final point in const [
      Offset(180, 10),
      Offset(201, 5),
      Offset(223, 10),
    ]) {
      canvas.drawCircle(point, 3, Paint()..color = Italia90.ink);
    }
    for (final star in const [
      Offset(112, 12),
      Offset(286, 12),
      Offset(29, 79),
      Offset(375, 79),
    ]) {
      final points = <Offset>[];
      for (var index = 0; index < 10; index++) {
        final angle = -math.pi / 2 + index * math.pi / 5;
        final radius = index.isEven ? 9.0 : 4.0;
        points.add(star + Offset(math.cos(angle), math.sin(angle)) * radius);
      }
      _polygon(canvas, points, star.dx < 40 ? Italia90.teamOne : Italia90.red);
    }
  }

  void _drawGroundMarks(Canvas canvas) {
    _polygon(canvas, const [
      Offset(0, 330),
      Offset(94, 320),
      Offset(135, 330),
    ], Italia90.green);
    _polygon(canvas, const [
      Offset(79, 342),
      Offset(153, 324),
      Offset(200, 342),
    ], Italia90.red);
    _polygon(canvas, const [
      Offset(247, 342),
      Offset(299, 324),
      Offset(356, 342),
    ], Italia90.teamOne);
    _polygon(canvas, const [
      Offset(337, 342),
      Offset(375, 324),
      Offset(402, 330),
      Offset(402, 342),
    ], Italia90.teamTwo);
    final line = Paint()
      ..color = Italia90.surface
      ..strokeWidth = 3;
    canvas.drawLine(const Offset(0, 324), const Offset(402, 324), line);
    canvas.drawLine(const Offset(128, 342), const Offset(201, 324), line);
    canvas.drawLine(const Offset(274, 342), const Offset(201, 324), line);
  }

  void _polygon(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant RankingPodiumArtwork oldDelegate) =>
      foreground != oldDelegate.foreground;
}

class RankingLaurelArtwork extends CustomPainter {
  const RankingLaurelArtwork();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 144, size.height / 240);
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(72, 0);
      canvas.scale(side, 1);
      final stem = Path()
        ..moveTo(47, 155)
        ..quadraticBezierTo(65, 130, 55, 95);
      canvas.drawPath(
        stem,
        Paint()
          ..color = Italia90.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      for (var index = 0; index < 7; index++) {
        final vertical = 99 + index * 7.0;
        final horizontal = 56 - math.max(0, index - 2) * 1.8;
        canvas.drawPath(
          Path()
            ..moveTo(horizontal, vertical + 7)
            ..quadraticBezierTo(
              horizontal - 11,
              vertical + 2,
              horizontal - 8,
              vertical - 4,
            )
            ..quadraticBezierTo(
              horizontal,
              vertical - 1,
              horizontal,
              vertical + 7,
            ),
          Paint()..color = Italia90.ink,
        );
        canvas.drawPath(
          Path()
            ..moveTo(horizontal, vertical + 7)
            ..quadraticBezierTo(
              horizontal + 10,
              vertical + 2,
              horizontal + 9,
              vertical - 5,
            )
            ..quadraticBezierTo(
              horizontal + 2,
              vertical - 1,
              horizontal,
              vertical + 7,
            ),
          Paint()..color = Italia90.ink,
        );
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RankingLaurelArtwork oldDelegate) => false;
}
