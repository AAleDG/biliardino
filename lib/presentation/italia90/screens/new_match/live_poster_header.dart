import 'package:flutter/material.dart';

import '../../theme/italia90_tokens.dart';

/// Full-height editorial poster for the live match screen.
///
/// The source image only supplies the editorial artwork. The overflow action
/// stays native and layered above it; the fixed back action belongs to the
/// screen layer outside this scrollable poster widget.
class LivePosterHeader extends StatelessWidget {
  const LivePosterHeader({super.key, required this.onReset, this.overlay});

  static const sourceWidth = 941.0;
  static const sourceHeight = 1672.0;

  // Keep only the header, scores and tricolour. Player content and actions
  // below this boundary are native widgets, not baked into the poster.
  static const visibleArtworkHeight = 1015.0;

  static double sourceHeightForWidth(double width) =>
      width * sourceHeight / sourceWidth;

  final VoidCallback? onReset;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final height = width * visibleArtworkHeight / sourceWidth;
      return Semantics(
        container: true,
        label: "Italia '90. Partita in corso",
        child: SizedBox(
          height: height,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: Image.asset(
                      'assets/italia90/live-poster-editoriale.png',
                      alignment: Alignment.topCenter,
                      fit: BoxFit.fitWidth,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                if (overlay != null) Positioned.fill(child: overlay!),
                Positioned(
                  top: 4,
                  right: 4,
                  child: KeyedSubtree(
                    key: const ValueKey('live-match-menu'),
                    child: PopupMenuButton<String>(
                      key: const ValueKey('new-match-reset'),
                      enabled: onReset != null,
                      tooltip: 'Altre opzioni partita',
                      icon: const Icon(Icons.more_horiz),
                      color: Italia90.surface,
                      onSelected: (_) => onReset?.call(),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'reset',
                          child: Text('Azzera punteggio'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
