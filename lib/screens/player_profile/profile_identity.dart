import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/player_stats.dart';
import '../../theme/app_theme.dart';
import '../../widgets/design/ranking_avatar.dart';
import '../../widgets/design/ranking_badges.dart';
import '../../widgets/design/profile_artwork.dart';

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key, required this.stats, required this.scene});
  final PlayerStats stats;
  final ui.Image? scene;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final scaler = MediaQuery.textScalerOf(context);
      final decorated =
          width >= 350 &&
          scaler.scale(1) <= 1 &&
          MediaQuery.sizeOf(context).height >= 450 &&
          stats.badges.length <= 2 &&
          _fits(
            context,
            stats.player.name,
            AppType.event.copyWith(fontSize: 48),
            width * .65,
          ) &&
          _fits(
            context,
            '${stats.points} pt',
            AppType.event.copyWith(fontSize: 34),
            150,
          );
      final content = Padding(
        padding: const EdgeInsets.all(AppSpace.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                stats.player.name,
                style: decorated
                    ? AppType.event.copyWith(fontSize: 48)
                    : AppType.screen,
              ),
            ),
            const SizedBox(height: AppSpace.small),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RankingAvatar(
                  name: stats.player.name,
                  size: decorated ? 76 : 58,
                ),
                const SizedBox(width: AppSpace.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.player.isArchived
                            ? 'Archiviato'
                            : stats.player.isPresent
                            ? 'In ufficio'
                            : 'Assente',
                        style: AppType.bodyStrong.copyWith(
                          color:
                              stats.player.isPresent && !stats.player.isArchived
                              ? AppColors.successPressed
                              : AppColors.ink,
                        ),
                      ),
                      Text(
                        '${stats.points} pt',
                        style: AppType.screen.copyWith(
                          color: AppColors.primary,
                          fontSize: decorated ? 34 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (decorated) const SizedBox(width: 88),
              ],
            ),
            if (stats.badges.isNotEmpty) ...[
              const SizedBox(height: AppSpace.medium),
              Container(
                constraints: decorated
                    ? BoxConstraints(maxWidth: width - 88)
                    : null,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                padding: const EdgeInsets.all(AppSpace.small),
                child: RankingBadges(badges: stats.badges),
              ),
            ],
          ],
        ),
      );
      if (!decorated) {
        return Container(
          key: const ValueKey('profile-identity-reflow'),
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(AppRadius.panel),
          ),
          child: content,
        );
      }
      return SizedBox(
        height: 232,
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: scene == null
                          ? null
                          : ProfileHeroArtwork(scene: scene!),
                    ),
                  ),
                ),
              ),
            ),
            content,
          ],
        ),
      );
    },
  );

  bool _fits(BuildContext context, String text, TextStyle style, double width) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: width);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }
}
