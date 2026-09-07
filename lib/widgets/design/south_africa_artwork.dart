import 'package:flutter/material.dart';
import 'artwork_paths.dart';

enum ArtworkMark { figure, mountedFigure, football, headerRibbon, cornerRibbon }

class SouthAfricaArtwork extends StatelessWidget {
  const SouthAfricaArtwork({
    super.key,
    required this.mark,
    this.width,
    this.height,
    this.monochrome,
    this.fit = BoxFit.contain,
  });
  final ArtworkMark mark;
  final double? width;
  final double? height;
  final Color? monochrome;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: SouthAfricaArtworkPainter(
              mark,
              monochrome: monochrome,
              fit: fit,
            ),
          ),
        ),
      ),
    ),
  );
}

class SouthAfricaArtworkPainter extends CustomPainter {
  const SouthAfricaArtworkPainter(
    this.mark, {
    this.monochrome,
    this.fit = BoxFit.contain,
  });
  final ArtworkMark mark;
  final Color? monochrome;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    final source = switch (mark) {
      ArtworkMark.figure => const Size(100, 220),
      ArtworkMark.mountedFigure => const Size(360, 240),
      ArtworkMark.football => const Size(120, 120),
      ArtworkMark.headerRibbon => const Size(402, 112),
      ArtworkMark.cornerRibbon => const Size(300, 132),
    };
    final target = applyBoxFit(fit, source, size).destination;
    canvas.save();
    canvas.translate(
      (size.width - target.width) / 2,
      (size.height - target.height) / 2,
    );
    canvas.scale(target.width / source.width, target.height / source.height);
    switch (mark) {
      case ArtworkMark.figure:
        drawFoosballFigure(canvas, monochrome);
      case ArtworkMark.mountedFigure:
        drawFoosballRod(canvas, monochrome);
      case ArtworkMark.football:
        drawFootball(canvas, monochrome);
      case ArtworkMark.headerRibbon:
        drawRibbonHeader(canvas, monochrome);
      case ArtworkMark.cornerRibbon:
        drawRibbonCorner(canvas, monochrome);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SouthAfricaArtworkPainter oldDelegate) =>
      oldDelegate.mark != mark ||
      oldDelegate.monochrome != monochrome ||
      oldDelegate.fit != fit;
}
