import 'package:flutter/material.dart';

import '../../theme/italia90_tokens.dart';
import '../../widgets/italia90_components.dart';

/// Semantic slots for the history accents shared by cards and sheets.
enum HistoryRibbon { header, card, footer }

/// Reuses the approved Italia diagonal motif for history decoration.
///
/// The component deliberately carries no information and is excluded from
/// the semantics tree so match content remains the responsibility of the
/// surrounding card.
class HistoryRibbonArtwork extends StatelessWidget {
  const HistoryRibbonArtwork(this.ribbon, {super.key, required this.height});

  final HistoryRibbon ribbon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = switch (ribbon) {
      HistoryRibbon.header => (
        background: Italia90.primary,
        stripe: Colors.white.withValues(alpha: 0.88),
      ),
      HistoryRibbon.card => (
        background: Italia90.teamTwoContainer,
        stripe: Italia90.red.withValues(alpha: 0.72),
      ),
      HistoryRibbon.footer => (
        background: Italia90.green,
        stripe: Colors.white.withValues(alpha: 0.88),
      ),
    };

    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: ItaliaDiagonalStripes(
            backgroundColor: colors.background,
            stripeColor: colors.stripe,
          ),
        ),
      ),
    );
  }
}
