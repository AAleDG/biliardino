import 'package:flutter/material.dart';

import '../theme/italia90_tokens.dart';

enum ItaliaBackdropVariant { home, homeDashboard, working, live }

/// Shared visual frame based on the user-selected Italia '90 poster proposal.
///
/// The artwork remains decorative; all readable content and interactions stay
/// in the Flutter widgets layered above it.
class ItaliaGraphicBackdrop extends StatelessWidget {
  const ItaliaGraphicBackdrop({
    super.key,
    required this.child,
    this.variant = ItaliaBackdropVariant.working,
  });
  final Widget child;
  final ItaliaBackdropVariant variant;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: _ItaliaBackdropArtwork(variant: variant),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

class _ItaliaBackdropArtwork extends StatelessWidget {
  const _ItaliaBackdropArtwork({required this.variant});

  final ItaliaBackdropVariant variant;

  @override
  Widget build(BuildContext context) {
    final opacity = switch (variant) {
      ItaliaBackdropVariant.home || ItaliaBackdropVariant.homeDashboard => 0.92,
      ItaliaBackdropVariant.working => 0.84,
      ItaliaBackdropVariant.live => 0.18,
    };
    final alignment = switch (variant) {
      ItaliaBackdropVariant.home ||
      ItaliaBackdropVariant.homeDashboard => Alignment.center,
      ItaliaBackdropVariant.working => const Alignment(0, 0.08),
      ItaliaBackdropVariant.live => const Alignment(0, 0.18),
    };
    final assetPath = switch (variant) {
      ItaliaBackdropVariant.homeDashboard =>
        'assets/italia90/backdrop-home-proposal-7.png',
      ItaliaBackdropVariant.home => 'assets/italia90/backdrop-proposal-2.png',
      ItaliaBackdropVariant.working || ItaliaBackdropVariant.live =>
        'assets/italia90/backdrop-working-petrol-amaranto.png',
    };

    return ColoredBox(
      color: Italia90.surface,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: alignment,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
