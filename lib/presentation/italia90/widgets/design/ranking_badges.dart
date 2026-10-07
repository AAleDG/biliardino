import 'package:flutter/material.dart';

import '../../../../models/player_badge.dart';
import '../../theme/italia90_tokens.dart';

/// Small, text-led achievement markers for ranking and profile surfaces.
class RankingBadges extends StatelessWidget {
  const RankingBadges({super.key, required this.badges});

  final List<PlayerBadge> badges;

  // Shared measurement constants keep podium fit checks stable when badge
  // content wraps at larger text sizes.
  static const contentPadding = EdgeInsets.symmetric(horizontal: 4);
  static const iconSize = 14.0;
  static const iconGap = 3.0;
  static const spacing = Italia90.xs;
  static const labelWidthInset = 4.0 + iconSize + iconGap;
  static const labelStyle = Italia90.caption;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Italia90.xs,
    runSpacing: Italia90.xs,
    children: [
      for (final badge in badges)
        Tooltip(
          message: badge.description,
          child: Chip(
            avatar: Icon(_iconFor(badge), size: 14),
            label: Text(badge.label),
            labelStyle: Italia90.caption.copyWith(
              color: _foregroundFor(badge),
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: _backgroundFor(badge),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ),
    ],
  );

  static IconData _iconFor(PlayerBadge badge) => switch (badge.code) {
    'leader' => Icons.emoji_events,
    'bomber' => Icons.sports_soccer,
    _ => Icons.local_fire_department,
  };

  static Color _backgroundFor(PlayerBadge badge) => switch (badge.code) {
    'leader' => Italia90.teamTwoContainer,
    'bomber' => Italia90.brickContainer,
    _ => Italia90.subtle,
  };

  static Color _foregroundFor(PlayerBadge badge) => switch (badge.code) {
    'leader' => Italia90.ink,
    'bomber' => Italia90.error,
    _ => Italia90.primary,
  };
}
