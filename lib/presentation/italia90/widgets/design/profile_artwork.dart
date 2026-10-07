import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/italia90_tokens.dart';

/// Italia '90 profile hero built from the shared approved palette.
///
/// The optional scene keeps the painter API compatible with the source
/// profile composition. The production composition does not load external
/// raster artwork.
class ProfileHeroArtwork extends CustomPainter {
  const ProfileHeroArtwork({this.scene});

  final ui.Image? scene;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 402, size.height / 232);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 402, 232),
      Paint()..color = Italia90.teamTwo,
    );

    _band(canvas, const [
      Offset(-18, 204),
      Offset(148, 0),
      Offset(188, 0),
      Offset(20, 232),
    ], Italia90.green);
    _band(canvas, const [
      Offset(38, 232),
      Offset(202, 0),
      Offset(232, 0),
      Offset(68, 232),
    ], Italia90.surface);
    _band(canvas, const [
      Offset(80, 232),
      Offset(244, 0),
      Offset(277, 0),
      Offset(113, 232),
    ], Italia90.red);
    _band(canvas, const [
      Offset(184, 232),
      Offset(336, 0),
      Offset(402, 0),
      Offset(402, 50),
      Offset(222, 232),
    ], Italia90.teamOne);

    final pitch = Path()
      ..moveTo(218, 232)
      ..lineTo(402, 88)
      ..lineTo(402, 232)
      ..close();
    canvas.drawPath(pitch, Paint()..color = Italia90.ink);

    final fieldLine = Paint()
      ..color = Italia90.surface.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(const Offset(278, 232), const Offset(402, 134), fieldLine);
    canvas.drawArc(
      const Rect.fromLTWH(300, 154, 116, 106),
      3.55,
      1.35,
      false,
      fieldLine,
    );
    canvas.drawCircle(const Offset(352, 190), 4, fieldLine);

    canvas.restore();
  }

  void _band(Canvas canvas, List<Offset> points, Color color) {
    canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant ProfileHeroArtwork oldDelegate) =>
      scene != oldDelegate.scene;
}

/// Small corner accent used by relationship cards.
class ProfileCornerSweep extends CustomPainter {
  const ProfileCornerSweep();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 160, size.height / 70);
    _ribbon(canvas, 0, Italia90.green);
    _ribbon(canvas, 27, Italia90.surface);
    _ribbon(canvas, 64, Italia90.red);
    _ribbon(canvas, 112, Italia90.teamOne);
    canvas.restore();
  }

  void _ribbon(Canvas canvas, double start, Color color) {
    final path = Path()
      ..moveTo(start, 70)
      ..cubicTo(start + 24, 66, start + 38, 54, 160, 0)
      ..lineTo(160, 13)
      ..cubicTo(start + 52, 59, start + 30, 69, start, 70)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant ProfileCornerSweep oldDelegate) => false;
}

/// Footer decoration retaining the source profile's below-fold visual beat.
class ProfileFooterArtwork extends CustomPainter {
  const ProfileFooterArtwork({this.scene});

  final ui.Image? scene;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 402, size.height / 76);
    _strip(canvas, 10, Italia90.green);
    _strip(canvas, 31, Italia90.surface);
    _strip(canvas, 51, Italia90.red);
    _strip(canvas, 65, Italia90.teamOne);

    final ball = Paint()..color = Italia90.ink;
    canvas.drawCircle(const Offset(328, 40), 22, ball);
    final seam = Paint()
      ..color = Italia90.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(const Offset(328, 40), 16, seam);
    canvas.drawLine(const Offset(311, 33), const Offset(345, 47), seam);
    canvas.drawLine(const Offset(315, 51), const Offset(340, 28), seam);
    canvas.restore();
  }

  void _strip(Canvas canvas, double top, Color color) {
    final path = Path()
      ..moveTo(0, top)
      ..cubicTo(98, top + 22, 238, top - 18, 402, top + 15)
      ..lineTo(402, top + 23)
      ..cubicTo(238, top - 10, 98, top + 30, 0, top + 9)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant ProfileFooterArtwork oldDelegate) =>
      scene != oldDelegate.scene;
}
