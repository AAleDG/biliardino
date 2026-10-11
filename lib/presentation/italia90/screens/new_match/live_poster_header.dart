import 'package:flutter/material.dart';

import '../../theme/italia90_tokens.dart';

/// Full-height editorial poster for the live match screen.
///
/// The source image only supplies the editorial artwork. Navigation and the
/// overflow action stay native controls layered above it.
class LivePosterHeader extends StatelessWidget {
  const LivePosterHeader({
    super.key,
    required this.onBack,
    required this.onReset,
  });

  final VoidCallback? onBack;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final height = width * 1672 / 941;
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
                Positioned(
                  top: 4,
                  left: 4,
                  child: _PosterIconButton(
                    tooltip: 'Torna alla composizione',
                    icon: Icons.arrow_back,
                    onPressed: onBack,
                    key: const ValueKey('new-match-back'),
                  ),
                ),
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

class _PosterIconButton extends StatelessWidget {
  const _PosterIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Italia90.surface.withValues(alpha: .86),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: Italia90.ink,
      constraints: const BoxConstraints.tightFor(
        width: Italia90.touch,
        height: Italia90.touch,
      ),
    ),
  );
}
