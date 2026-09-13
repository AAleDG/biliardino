import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'pass_contours.dart';

enum PassRibbonKind { header, corner, footer }

class PassRibbons extends CustomPainter {
  const PassRibbons(this.kind, {this.scene});
  final PassRibbonKind kind;
  final ui.Image? scene;
  @override
  void paint(Canvas canvas, Size size) {
    final dimensions = switch (kind) {
      PassRibbonKind.header => const Size(466, 163),
      PassRibbonKind.corner => const Size(190, 57),
      PassRibbonKind.footer => const Size(463, 149),
    };
    final contours = switch (kind) {
      PassRibbonKind.header => PassContours.header(),
      PassRibbonKind.corner => PassContours.cornerMore(),
      PassRibbonKind.footer => PassContours.sharedFooter(),
    };
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(
      size.width / dimensions.width,
      size.height / dimensions.height,
    );
    for (final item in contours) {
      canvas.drawPath(
        item.$1,
        Paint()
          ..shader = ui.Gradient.linear(item.$4, item.$5, item.$3, const [
            0,
            .25,
            .5,
            .75,
            1,
          ]),
      );
    }
    canvas.restore();
    if (kind == PassRibbonKind.footer && scene != null) {
      final diameter = size.width * 235 / 461;
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      canvas.drawImageRect(
        scene!,
        const Rect.fromLTWH(957, 428, 263, 264),
        Rect.fromLTWH(
          size.width * 222 / 461,
          size.height * 74 / 149,
          diameter,
          diameter,
        ),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PassRibbons old) =>
      kind != old.kind || scene != old.scene;
}
