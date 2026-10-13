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
                for (var index = 0; index < items.length; index++)
                  _RecognitionItem(
                    key: ValueKey('$keyPrefix-achievement-$index'),
                    item: items[index],
                    width: width,
                    itemKey:
                        '$keyPrefix-achievement-${items[index].ownerId}-${items[index].badge.code}',
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

class _RecognitionItem extends StatelessWidget {
  const _RecognitionItem({
    super.key,
    required this.item,
    required this.width,
    required this.itemKey,
  });

  final RankingRecognition item;
  final double width;
  final String itemKey;

  @override
  Widget build(BuildContext context) {
    final visibleLabel = '${item.badge.label}: ${item.ownerName}';
    final semanticsLabel = '$visibleLabel. ${item.badge.description}';
    return SizedBox(
      key: ValueKey(itemKey),
      width: width,
      child: Tooltip(
        message: semanticsLabel,
        excludeFromSemantics: true,
        child: Semantics(
          container: true,
          label: semanticsLabel,
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Italia90.subtle, width: 2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    RankingRecognitions._iconFor(item.badge),
                    size: 20,
                    color: item.badge.code == 'leader'
                        ? Italia90.success
                        : Italia90.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.badge.label,
                        style: Italia90.label.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.ownerName,
                        style: Italia90.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.badge.description,
                        style: Italia90.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
