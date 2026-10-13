import 'package:flutter/material.dart';

import '../../../../models/player_stats.dart';
import '../../theme/italia90_tokens.dart';
import '../../widgets/design/ranking_badges.dart';
import '../../widgets/design/ranking_avatar.dart';
import '../../widgets/design/ranking_metrics.dart';

/// Responsive row shared by the general and goals ranking ledgers.
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
  final String metric;
  final String detail;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
        key: ValueKey('leaderboard-row-${stats.player.id}'),
        container: true,
        button: true,
        enabled: true,
        hint: 'Apri il profilo',
        label: 'Posizione $rank: ${stats.player.name}. $metric. $detail.'
            '${stats.badges.isEmpty ? '' : ' ${stats.badges.map((badge) => badge.label).join(', ')}.'}',
        onTap: onOpen,
        child: ExcludeSemantics(
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 340 ||
                      MediaQuery.textScalerOf(context).scale(16) > 22;
                  final identity = Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$rank',
                          textAlign: TextAlign.center,
                          style: Italia90.heading.copyWith(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RankingAvatar(name: stats.player.name, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats.player.name,
                              style: Italia90.title.copyWith(fontSize: 18),
                            ),
                            if (compact)
                              Text(
                                detail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Italia90.caption,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final metrics = RankingMetrics(
                    id: stats.player.id,
                    metrics: [
                      RankingMetricSpec(
                        keySuffix: 'pg',
                        label: 'PG',
                        value: stats.games.toString(),
                      ),
                      RankingMetricSpec(
                        keySuffix: 'gol',
                        label: 'GOL',
                        value: stats.goalsScored.toString(),
                      ),
                      RankingMetricSpec(
                        keySuffix: 'v',
                        label: 'V',
                        value: stats.wins.toString(),
                      ),
                      RankingMetricSpec(
                        keySuffix: 'pt',
                        label: 'PT',
                        value: stats.points.toString(),
                        emphasized: true,
                      ),
                    ],
                  );

                  final badges = stats.badges.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(left: 76, top: 6),
                          child: RankingBadges(badges: stats.badges),
                        );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [identity, metrics, badges],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: identity),
                      _WideMetric(
                        value: stats.games.toString(),
                        keySuffix: 'pg',
                        id: stats.player.id,
                      ),
                      _WideMetric(
                        value: stats.goalsScored.toString(),
                        keySuffix: 'gol',
                        id: stats.player.id,
                      ),
                      _WideMetric(
                        value: stats.wins.toString(),
                        keySuffix: 'v',
                        id: stats.player.id,
                      ),
                      _WideMetric(
                        value: stats.points.toString(),
                        keySuffix: 'pt',
                        id: stats.player.id,
                        emphasized: true,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
}

class _WideMetric extends StatelessWidget {
  const _WideMetric({
    required this.value,
    required this.keySuffix,
    required this.id,
    this.emphasized = false,
  });

  final String value;
  final String keySuffix;
  final String id;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => SizedBox(
        key: ValueKey('leaderboard-$id-$keySuffix'),
        width: 34,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Italia90.body.copyWith(
              fontSize: 18,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      );
}
