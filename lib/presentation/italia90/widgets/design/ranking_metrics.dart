import 'package:flutter/material.dart';

import '../../theme/italia90_tokens.dart';

/// Describes one metric rendered in a compact leaderboard row.
class RankingMetricSpec {
  const RankingMetricSpec({
    required this.keySuffix,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String keySuffix;
  final String label;
  final String value;
  final bool emphasized;
}

/// Responsive metric layout shared by player and team leaderboard rows.
///
/// Normal text keeps the compact four-column presentation. At large text the
/// metrics reflow into two columns, or one column when the available width is
/// too small. Text is never scaled down to force four columns to fit.
class RankingMetrics extends StatelessWidget {
  const RankingMetrics({
    super.key,
    required this.id,
    required this.metrics,
  });

  static const _leftInset = 76.0;
  static const _largeTextColumnThreshold = 240.0;
  static const _spacing = 8.0;

  final String id;
  final List<RankingMetricSpec> metrics;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return Padding(
      padding: const EdgeInsets.only(left: _leftInset, top: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!largeText) {
            return Row(
              children: [
                for (final metric in metrics) Expanded(child: _tile(metric)),
              ],
            );
          }

          final twoColumns = constraints.maxWidth >= _largeTextColumnThreshold;
          final tileWidth = twoColumns
              ? (constraints.maxWidth - _spacing) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: [
              for (final metric in metrics)
                SizedBox(width: tileWidth, child: _tile(metric)),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(RankingMetricSpec metric) => KeyedSubtree(
        key: ValueKey('leaderboard-$id-${metric.keySuffix}'),
        child: _RankingMetricTile(metric: metric),
      );
}

class _RankingMetricTile extends StatelessWidget {
  const _RankingMetricTile({required this.metric});

  final RankingMetricSpec metric;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 2,
            style: Italia90.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            metric.value,
            style: Italia90.body.copyWith(
              fontSize: 18,
              fontWeight: metric.emphasized ? FontWeight.w800 : FontWeight.w700,
              color: metric.emphasized ? Italia90.teamOne : Italia90.ink,
            ),
          ),
        ],
      );
}
