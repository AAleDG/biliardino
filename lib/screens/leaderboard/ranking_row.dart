import 'package:flutter/material.dart';
import '../../models/player_stats.dart';
import '../../theme/app_theme.dart';
import '../../widgets/design/ranking_avatar.dart';
import '../../widgets/design/ranking_badges.dart';

class RankingRow extends StatelessWidget {
  const RankingRow({
    super.key,
    required this.rank,
    required this.stats,
    required this.metric,
    required this.detail,
    required this.onOpen,
  });
  final int rank;
  final PlayerStats stats;
  final String metric, detail;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('leaderboard-row-${stats.player.id}'),
    container: true,
    button: true,
    enabled: true,
    label:
        'Posizione $rank: ${stats.player.name}. $metric. $detail. ${stats.badges.map((b) => b.label).join(', ')}',
    onTap: onOpen,
    child: ExcludeSemantics(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metricPainter = TextPainter(
                text: TextSpan(text: metric, style: AppType.section),
                textScaler: MediaQuery.textScalerOf(context),
                textDirection: Directionality.of(context),
              )..layout();
              final wideMetric =
                  metricPainter.width > constraints.maxWidth * .23;
              metricPainter.dispose();
              final compact =
                  wideMetric ||
                  rank > 99 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                  constraints.maxWidth < 340;
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stats.player.name, style: AppType.player),
                  Text(
                    detail,
                    style: AppType.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (stats.badges.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: RankingBadges(badges: stats.badges),
                    ),
                  if (compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        metric,
                        style: AppType.section.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              );
              if (compact) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$rank',
                        style: AppType.section.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: info),
                    ],
                  ),
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipPath(
                      clipper: const _Endcap(),
                      child: Container(
                        width: 42,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 12),
                        color: AppColors.primary,
                        child: Text(
                          '$rank',
                          style: AppType.section.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Center(
                        child: RankingAvatar(name: stats.player.name, size: 36),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: info,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ClipPath(
                      clipper: const _Endcap(reverse: true),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 60),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.fromLTRB(17, 12, 10, 12),
                        color: AppColors.primary,
                        child: Text(
                          metric,
                          style: AppType.section.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _Endcap extends CustomClipper<Path> {
  const _Endcap({this.reverse = false});
  final bool reverse;
  @override
  Path getClip(Size size) => reverse
      ? (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..lineTo(10, size.height / 2)
          ..close())
      : (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width - 10, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width - 10, size.height)
          ..lineTo(0, size.height)
          ..close());
  @override
  bool shouldReclip(covariant _Endcap old) => reverse != old.reverse;
}
