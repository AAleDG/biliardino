import 'package:flutter/material.dart';
import '../../models/player_badge.dart';
import '../../models/ranking_stats.dart';
import '../../theme/app_theme.dart';
import 'pass_ticket.dart';
import 'ranking_award_ticket_artwork.dart';
import 'ranking_badges.dart';
import 'ranking_identity.dart';
import 'ticket_perforation.dart';

/// Informational awards; navigation remains with the original podium/rows.
class RankingAwardTicket extends StatelessWidget {
  const RankingAwardTicket({
    super.key,
    required this.stats,
    required this.badges,
  });
  final RankingStats stats;
  final List<PlayerBadge> badges;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        'Riconoscimenti di ${stats.name}: '
        '${badges.map((badge) => '${badge.label}. ${badge.description}').join('; ')}',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stubWidth = constraints.maxWidth * .28;
          const nameStyle = AppType.section;
          final name = TextPainter(
            text: TextSpan(text: stats.name, style: nameStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 2,
          )..layout(maxWidth: (stubWidth - 24).clamp(1, double.infinity));
          final stacked =
              constraints.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
              name.didExceedMaxLines;
          name.dispose();
          final identity = RankingIdentity(names: stats.memberNames, size: 52);
          final playerName = Text(
            stats.name,
            textAlign: stacked ? TextAlign.start : TextAlign.center,
            style: nameStyle,
          );
          final awards = Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < badges.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                  _AwardDetail(badge: badges[i]),
                ],
              ],
            ),
          );
          return Material(
            color: AppColors.surface,
            elevation: 1,
            shadowColor: AppColors.ink.withValues(alpha: .14),
            shape: const PassTicketShape(),
            clipBehavior: Clip.antiAlias,
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ColoredBox(
                        color: AppColors.yellow,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              identity,
                              const SizedBox(width: 12),
                              Expanded(child: playerName),
                            ],
                          ),
                        ),
                      ),
                      awards,
                    ],
                  )
                : CustomPaint(
                    painter: RankingAwardTicketArtwork(
                      identityWidth: stubWidth,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: stubWidth,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                16,
                                12,
                                44,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: identity,
                                  ),
                                  const SizedBox(height: 8),
                                  playerName,
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: SizedBox(
                              width: 1,
                              child: CustomPaint(painter: TicketPerforation()),
                            ),
                          ),
                          Expanded(child: awards),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    ),
  );
}

class _AwardDetail extends StatelessWidget {
  const _AwardDetail({required this.badge});
  final PlayerBadge badge;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      RankingBadge(
        badge: badge,
        labelStyle: RankingBadges.labelStyle.copyWith(fontSize: 16),
        iconSize: 16,
        icon: switch (badge.code) {
          'grinder' => Icons.event_available,
          'dominant' => Icons.bolt,
          'rivalry' => Icons.sports_martial_arts,
          _ => Icons.local_fire_department,
        },
      ),
      const SizedBox(height: 8),
      Text(badge.description, style: AppType.caption.copyWith(fontSize: 14)),
    ],
  );
}
