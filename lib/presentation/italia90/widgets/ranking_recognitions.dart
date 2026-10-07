import 'package:flutter/material.dart';

import '../../../models/player_badge.dart';
import '../theme/italia90_tokens.dart';

class RankingRecognition {
  const RankingRecognition({
    required this.ownerId,
    required this.ownerName,
    required this.badge,
  });

  final String ownerId;
  final String ownerName;
  final PlayerBadge badge;
}

class RankingRecognitions extends StatelessWidget {
  const RankingRecognitions({
    super.key,
    required this.items,
    required this.keyPrefix,
  });

  final List<RankingRecognition> items;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: 'Riconoscimenti',
      child: Container(
        color: Italia90.panel,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 1
                : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final item in items)
                  SizedBox(
                    key: ValueKey(
                      '$keyPrefix-achievement-${item.ownerId}-${item.badge.code}',
                    ),
                    width: width,
                    child: Tooltip(
                      message: '${item.badge.description} ${item.ownerName}',
                      excludeFromSemantics: true,
                      child: Semantics(
                        label: '${item.badge.label}: ${item.ownerName}',
                        excludeSemantics: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Italia90.subtle,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _iconFor(item.badge),
                                size: 20,
                                color: item.badge.code == 'leader'
                                    ? Italia90.success
                                    : Italia90.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.badge.label,
                                  style: Italia90.label.copyWith(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static IconData _iconFor(PlayerBadge badge) => switch (badge.code) {
    'leader' => Icons.emoji_events_outlined,
    'bomber' => Icons.track_changes,
    'grinder' => Icons.local_fire_department_outlined,
    'dominant' => Icons.bolt,
    'rivalry' => Icons.sports_soccer,
    _ => Icons.local_fire_department_outlined,
  };
}
