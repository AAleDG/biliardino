import 'package:flutter/material.dart';
import '../../models/player_badge.dart';
import '../../theme/app_theme.dart';

class RankingBadges extends StatelessWidget {
  const RankingBadges({super.key, required this.badges});
  final List<PlayerBadge> badges;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 4,
    runSpacing: 4,
    children: [
      for (final badge in badges)
        Tooltip(
          message: badge.description,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: badge.code == 'leader'
                    ? AppColors.yellow
                    : badge.code == 'bomber'
                    ? AppColors.error
                    : AppColors.outline,
              ),
            ),
            child: Text(
              badge.label,
              textAlign: TextAlign.center,
              style: AppType.caption.copyWith(color: AppColors.ink),
            ),
          ),
        ),
    ],
  );
}
