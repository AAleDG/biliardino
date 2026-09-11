import 'package:flutter/material.dart';
import '../../models/player_badge.dart';
import '../../theme/app_theme.dart';

class RankingBadges extends StatelessWidget {
  const RankingBadges({super.key, required this.badges});
  final List<PlayerBadge> badges;
  static const contentPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 4,
  );
  static const iconSize = 13.0;
  static const iconGap = 3.0;
  static const spacing = 4.0;
  static double get labelWidthInset =>
      contentPadding.horizontal + iconSize + iconGap;

  static const labelStyle = TextStyle(
    fontFamily: AppType.displayFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: spacing,
    runSpacing: spacing,
    children: [for (final badge in badges) _Badge(badge: badge)],
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});
  final PlayerBadge badge;
  @override
  Widget build(BuildContext context) {
    final leader = badge.code == 'leader';
    final bomber = badge.code == 'bomber';
    final color = leader
        ? AppColors.yellow
        : bomber
        ? AppColors.error
        : AppColors.primary;
    final foreground = leader ? AppColors.ink : AppColors.onPrimary;
    return Tooltip(
      message: badge.description,
      child: CustomPaint(
        painter: _RibbonBadge(color),
        child: Padding(
          padding: RankingBadges.contentPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                leader
                    ? Icons.emoji_events
                    : bomber
                    ? Icons.sports_soccer
                    : Icons.local_fire_department,
                size: RankingBadges.iconSize,
                color: foreground,
              ),
              const SizedBox(width: RankingBadges.iconGap),
              Flexible(
                child: Text(
                  badge.label,
                  textAlign: TextAlign.center,
                  style: RankingBadges.labelStyle.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonBadge extends CustomPainter {
  const _RibbonBadge(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tails = Path()
      ..moveTo(0, 3)
      ..lineTo(w, 3)
      ..lineTo(w - 3, h / 2)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..lineTo(3, h / 2)
      ..close();
    canvas.drawPath(
      tails,
      Paint()..color = Color.lerp(color, AppColors.ink, .25)!,
    );
    canvas.drawRect(Rect.fromLTRB(6, 0, w - 6, h - 2), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RibbonBadge old) => color != old.color;
}
