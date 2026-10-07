import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../models/player_stats.dart';
import '../../theme/italia90_tokens.dart';
import '../../widgets/design/ranking_avatar.dart';
import '../../widgets/ranking_recognitions.dart';

/// Identity block shared by the player profile and future profile surfaces.
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key, required this.stats, this.scene});

  final PlayerStats stats;
  final ui.Image? scene;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final stacked =
          width < 320 || MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final status = stats.player.isArchived
          ? 'Archiviato'
          : stats.player.isPresent
          ? 'In ufficio'
          : 'Assente';
      final statusColor = stats.player.isPresent && !stats.player.isArchived
          ? Italia90.success
          : Italia90.ink;
      final points = Semantics(
        label: '${stats.points} punti',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${stats.points}',
                style: Italia90.display.copyWith(
                  fontSize: 44,
                  color: Italia90.primary,
                ),
              ),
            ),
            Text(
              'punti',
              style: Italia90.label.copyWith(
                fontSize: 13,
                color: Italia90.primary,
              ),
            ),
          ],
        ),
      );
      final identity = Row(
        children: [
          ExcludeSemantics(
            child: RankingAvatar(name: stats.player.name, size: 64),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    stats.player.name,
                    key: const ValueKey('profile-player-name'),
                    style: Italia90.title.copyWith(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    ExcludeSemantics(
                      child: Icon(Icons.circle, size: 7, color: statusColor),
                    ),
                    Text(
                      status,
                      style: Italia90.body.copyWith(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!stacked) ...[
            const SizedBox(width: 14),
            SizedBox(width: width * .25, child: points),
          ],
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('profile-identity-surface'),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Italia90.success, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                if (stacked) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: width * .5, child: points),
                  ),
                ],
              ],
            ),
          ),
          if (stats.badges.isNotEmpty) ...[
            const SizedBox(height: 10),
            RankingRecognitions(
              key: const ValueKey('profile-recognitions'),
              keyPrefix: 'profile',
              items: [
                for (final badge in stats.badges)
                  RankingRecognition(
                    ownerId: stats.player.id,
                    ownerName: stats.player.name,
                    badge: badge,
                  ),
              ],
            ),
          ],
        ],
      );
    },
  );
}
