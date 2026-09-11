import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Approved Classifica candidate-2 geometry; player information stays in widgets.
/// All coordinates use a 402 x 316 design space. Player data is never painted.
class RankingPodiumArtwork extends CustomPainter {
  const RankingPodiumArtwork({required this.scene, this.foreground = false});
  final ui.Image? scene;
  final bool foreground;

  static Color light(Color c, double amount) =>
      Color.lerp(c, Colors.white, amount)!;
  static Color dark(Color c, double amount) =>
      Color.lerp(c, AppColors.ink, amount)!;

  void fill(Canvas c, Path p, Color color, {bool reverse = false}) {
    c.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          begin: reverse ? Alignment.topRight : Alignment.topLeft,
          end: reverse ? Alignment.bottomLeft : Alignment.bottomRight,
          colors: [light(color, .12), color, dark(color, .22)],
          stops: const [0, .5, 1],
        ).createShader(p.getBounds()),
    );
  }

  void ribbon(Canvas c, Color color, List<Offset> pts, {bool fold = false}) {
    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i + 2 < pts.length; i += 3) {
      p.cubicTo(
        pts[i].dx,
        pts[i].dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
        pts[i + 2].dx,
        pts[i + 2].dy,
      );
    }
    p.close();
    final right = p.getBounds().center.dx > 201;
    c.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          begin: foreground
              ? Alignment.topCenter
              : (right ? Alignment.topRight : Alignment.topLeft),
          end: foreground
              ? Alignment.bottomCenter
              : (right ? Alignment.bottomLeft : Alignment.bottomRight),
          colors: [
            dark(color, .34),
            color,
            light(color, .38),
            color,
            dark(color, fold ? .48 : .30),
          ],
          stops: const [0, .20, .43, .65, 1],
        ).createShader(p.getBounds()),
    );
  }

  void figure(Canvas c, {required bool right}) {
    if (scene == null) return;
    c.save();
    if (right) {
      c.translate(402, 0);
      c.scale(-1, 1);
    }
    c.translate(30, 72);
    c.rotate(.32);
    // Reuses an intact black figure and rod fragment from the approved scene.
    // Clip before the separate blue figure. No source bitmap is edited.
    c.drawImageRect(
      scene!,
      const Rect.fromLTWH(0, 0, 790, 695),
      const Rect.fromLTWH(-100, -50, 140, 123),
      Paint()..filterQuality = FilterQuality.high,
    );
    c.restore();
  }

  void block(Canvas c, Rect bounds, Color color, {int side = 0}) {
    // Side blocks recede toward the center; the winner occludes their rear ends.
    const depth = 11.0;
    final front = side < 0
        ? Rect.fromLTRB(
            bounds.left,
            bounds.top,
            bounds.right - 13,
            bounds.bottom,
          )
        : side > 0
        ? Rect.fromLTRB(
            bounds.left + 13,
            bounds.top,
            bounds.right,
            bounds.bottom,
          )
        : bounds;
    final shift = side < 0
        ? 13.0
        : side > 0
        ? -13.0
        : 0.0;
    final top = Path()
      ..moveTo(front.left, front.top)
      ..lineTo(front.left + (side == 0 ? depth : shift), front.top - depth)
      ..lineTo(front.right + (side == 0 ? -depth : shift), front.top - depth)
      ..lineTo(front.right, front.top)
      ..close();
    fill(c, top, light(color, .32));
    fill(c, Path()..addRect(front), color);
    if (side != 0) {
      final edge = side < 0 ? front.right : front.left;
      final face = Path()
        ..moveTo(edge, front.top)
        ..lineTo(edge + shift, front.top - depth)
        ..lineTo(edge + shift, front.bottom - depth)
        ..lineTo(edge, front.bottom)
        ..close();
      fill(c, face, dark(color, .42), reverse: side > 0);
    }
    final highlight = Path()
      ..moveTo(front.left, front.top)
      ..lineTo(front.right, front.top);
    c.drawPath(
      highlight,
      Paint()
        ..color = light(color, .45).withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 402, size.height / 316);
    if (!foreground) {
      // Side sweeps leave generous ivory reading columns.
      ribbon(canvas, AppColors.primary, const [
        Offset(-15, 17),
        Offset(36, 47),
        Offset(86, 56),
        Offset(119, 102),
        Offset(139, 133),
        Offset(144, 180),
        Offset(143, 215),
        Offset(125, 135),
        Offset(60, 92),
        Offset(-15, 47),
      ]);
      ribbon(canvas, AppColors.yellow, const [
        Offset(-12, 76),
        Offset(15, 143),
        Offset(53, 190),
        Offset(135, 224),
        Offset(78, 206),
        Offset(24, 169),
        Offset(-12, 117),
        Offset(-12, 109),
        Offset(-12, 90),
        Offset(-12, 76),
      ]);
      ribbon(canvas, AppColors.error, const [
        Offset(-12, 119),
        Offset(29, 160),
        Offset(71, 199),
        Offset(132, 231),
        Offset(65, 216),
        Offset(19, 173),
        Offset(-12, 144),
        Offset(-12, 136),
        Offset(-12, 128),
        Offset(-12, 119),
      ]);
      ribbon(canvas, AppColors.primary, const [
        Offset(-15, 158),
        Offset(19, 205),
        Offset(61, 235),
        Offset(117, 260),
        Offset(53, 246),
        Offset(12, 230),
        Offset(-15, 204),
        Offset(-15, 190),
        Offset(-15, 176),
        Offset(-15, 158),
      ]);
      ribbon(canvas, AppColors.error, const [
        Offset(415, 21),
        Offset(355, 50),
        Offset(310, 77),
        Offset(279, 116),
        Offset(311, 88),
        Offset(352, 72),
        Offset(415, 49),
        Offset(415, 40),
        Offset(415, 31),
        Offset(415, 21),
      ]);
      ribbon(canvas, AppColors.success, const [
        Offset(416, 76),
        Offset(372, 139),
        Offset(344, 196),
        Offset(272, 226),
        Offset(340, 213),
        Offset(389, 177),
        Offset(416, 124),
        Offset(416, 108),
        Offset(416, 92),
        Offset(416, 76),
      ]);
      ribbon(canvas, AppColors.primary, const [
        Offset(418, 133),
        Offset(384, 200),
        Offset(346, 229),
        Offset(293, 253),
        Offset(361, 234),
        Offset(405, 202),
        Offset(418, 180),
        Offset(418, 164),
        Offset(418, 149),
        Offset(418, 133),
      ]);
      ribbon(canvas, AppColors.yellow, const [
        Offset(418, 180),
        Offset(377, 218),
        Offset(335, 252),
        Offset(281, 270),
        Offset(348, 262),
        Offset(395, 238),
        Offset(418, 218),
        Offset(418, 206),
        Offset(418, 193),
        Offset(418, 180),
      ]);
      // Two separate folds make the yellow/green loop; center stays transparent.
      ribbon(canvas, AppColors.yellow, const [
        Offset(143, 210),
        Offset(142, 157),
        Offset(107, 98),
        Offset(120, 58),
        Offset(130, 17),
        Offset(176, -2),
        Offset(217, 10),
        Offset(160, 4),
        Offset(139, 42),
        Offset(139, 73),
        Offset(137, 119),
        Offset(157, 166),
        Offset(153, 210),
      ]);
      ribbon(canvas, AppColors.success, const [
        Offset(201, 7),
        Offset(250, 4),
        Offset(277, 37),
        Offset(282, 76),
        Offset(286, 123),
        Offset(252, 165),
        Offset(270, 213),
        Offset(253, 192),
        Offset(249, 168),
        Offset(262, 117),
        Offset(280, 63),
        Offset(247, 24),
        Offset(201, 7),
      ]);
      ribbon(canvas, AppColors.yellow, const [
        Offset(282, 76),
        Offset(299, 114),
        Offset(274, 153),
        Offset(270, 213),
        Offset(257, 193),
        Offset(258, 158),
        Offset(267, 126),
        Offset(278, 102),
        Offset(285, 87),
        Offset(282, 76),
      ], fold: true);
      figure(canvas, right: false);
      figure(canvas, right: true);
      block(
        canvas,
        const Rect.fromLTWH(19, 232, 124, 76),
        AppColors.primary,
        side: -1,
      );
      block(
        canvas,
        const Rect.fromLTWH(260, 239, 123, 69),
        AppColors.success,
        side: 1,
      );
      block(canvas, const Rect.fromLTWH(143, 211, 117, 97), AppColors.yellow);
    } else {
      // Front fan connects the stage and partially covers the ball at its foot.
      ribbon(canvas, AppColors.yellow, const [
        Offset(-15, 316),
        Offset(74, 280),
        Offset(153, 263),
        Offset(201, 269),
        Offset(131, 282),
        Offset(67, 300),
        Offset(16, 321),
        Offset(5, 321),
        Offset(-5, 319),
        Offset(-15, 316),
      ]);
      ribbon(canvas, AppColors.ink, const [
        Offset(15, 316),
        Offset(87, 290),
        Offset(150, 276),
        Offset(196, 273),
        Offset(156, 292),
        Offset(130, 305),
        Offset(111, 324),
        Offset(82, 322),
        Offset(46, 319),
        Offset(15, 316),
      ]);
      ribbon(canvas, AppColors.error, const [
        Offset(85, 323),
        Offset(117, 302),
        Offset(165, 285),
        Offset(202, 278),
        Offset(185, 296),
        Offset(164, 313),
        Offset(143, 326),
        Offset(124, 326),
        Offset(104, 325),
        Offset(85, 323),
      ]);
      ribbon(canvas, AppColors.primary, const [
        Offset(207, 270),
        Offset(277, 277),
        Offset(347, 300),
        Offset(419, 317),
        Offset(348, 314),
        Offset(285, 307),
        Offset(253, 298),
        Offset(237, 289),
        Offset(221, 279),
        Offset(207, 270),
      ]);
      ribbon(canvas, AppColors.ink, const [
        Offset(215, 278),
        Offset(246, 288),
        Offset(278, 305),
        Offset(301, 325),
        Offset(269, 325),
        Offset(244, 323),
        Offset(222, 321),
        Offset(219, 307),
        Offset(217, 292),
        Offset(215, 278),
      ]);
      // Native source rectangle holds only the already approved football.
      if (scene != null) {
        canvas.drawImageRect(
          scene!,
          const Rect.fromLTWH(957, 428, 263, 264),
          const Rect.fromLTWH(165, 270, 74, 74),
          Paint()..filterQuality = FilterQuality.high,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RankingPodiumArtwork old) =>
      scene != old.scene || foreground != old.foreground;
}
