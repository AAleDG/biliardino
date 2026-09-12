import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'south_africa_artwork.dart';

/// Native app-bar behavior and safe areas, with live type and noninteractive art.
/// Large text and compact phones trade decoration for content space.
PreferredSizeWidget brandAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  Widget? leading,
  bool compactTitle = false,
  bool showArtwork = true,
}) {
  final media = MediaQuery.of(context);
  final compact = media.size.height < 650 || media.textScaler.scale(1) > 1.3;
  final titleStyle = compactTitle && compact ? AppType.section : AppType.screen;
  final titleLines = compactTitle && compact ? 1 : 2;
  final hasLeading = leading != null || Navigator.of(context).canPop();
  final titleWidth = math.max(
    1.0,
    media.size.width - 32 - (hasLeading ? 56 : 0) - (actions?.length ?? 0) * 48,
  );
  final titleMetrics = TextPainter(
    text: TextSpan(text: title, style: titleStyle),
    textScaler: media.textScaler,
    textDirection: Directionality.of(context),
    maxLines: titleLines,
  )..layout(maxWidth: titleWidth);
  final toolbarHeight = math.max(48.0, titleMetrics.height + 8);
  titleMetrics.dispose();
  return AppBar(
    title: Text(
      title,
      maxLines: titleLines,
      style: titleStyle.copyWith(color: AppColors.ink),
    ),
    actions: actions,
    leading: leading,
    toolbarHeight: toolbarHeight,
    bottom: !showArtwork || (compactTitle && compact)
        ? null
        : PreferredSize(
            preferredSize: Size.fromHeight(compact ? 12 : 56),
            child: SizedBox(
              height: compact ? 12 : 56,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: compact ? 12 : 36,
                    child: const SouthAfricaArtwork(
                      mark: ArtworkMark.headerRibbon,
                      fit: BoxFit.fill,
                    ),
                  ),
                  if (!compact)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      width: 120,
                      height: 56,
                      child: SouthAfricaArtwork(
                        mark: ArtworkMark.mountedFigure,
                      ),
                    ),
                ],
              ),
            ),
          ),
  );
}

class RibbonBackdrop extends StatelessWidget {
  const RibbonBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned(
        left: 0,
        bottom: 0,
        width: 220,
        height: 96,
        child: SouthAfricaArtwork(mark: ArtworkMark.cornerRibbon),
      ),
      child,
    ],
  );
}
