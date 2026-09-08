import 'package:flutter/material.dart';
import '../../models/player_stats.dart';
import '../../theme/app_theme.dart';
import '../avatar.dart';
import 'ranking_badges.dart';

/// Shared podium for points and scorers; opens profiles through its owner.
class RankingPodium extends StatefulWidget {
  const RankingPodium({
    super.key,
    required this.top,
    required this.metricLabel,
    required this.onOpen,
  });
  final List<PlayerStats> top;
  final String Function(PlayerStats) metricLabel;
  final ValueChanged<String> onOpen;
  @override
  State<RankingPodium> createState() => _RankingPodiumState();
}

class _RankingPodiumState extends State<RankingPodium>
    with SingleTickerProviderStateMixin, MotionAwareState {
  late final AnimationController _entry;
  bool _played = false;
  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: AppMotion.podium);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_played) {
      _played = true;
      if (!reduceMotion) {
        _entry.forward();
      }
    }
    if (!visible && _played) settleMotion();
  }

  @override
  void settleMotion() {
    _entry.stop();
    _entry.value = 1;
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 350 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final entries = widget.top.take(3).toList();
      final order = !stacked && entries.length == 3
          ? [1, 0, 2]
          : List.generate(entries.length, (i) => i);
      final children = [
        for (final i in order)
          _PodiumPlace(
            rank: i + 1,
            stats: entries[i],
            metric: widget.metricLabel(entries[i]),
            stacked: stacked,
            onTap: () => widget.onOpen(entries[i].player.id),
          ),
      ];
      return AnimatedBuilder(
        animation: _entry,
        builder: (_, child) => Transform.translate(
          offset: Offset(
            0,
            12 * (1 - Curves.easeOutCubic.transform(_entry.value)),
          ),
          child: child,
        ),
        child: stacked
            ? Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1) const SizedBox(height: 12),
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final child in children) Expanded(child: child),
                ],
              ),
      );
    },
  );
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.rank,
    required this.stats,
    required this.metric,
    required this.stacked,
    required this.onTap,
  });
  final int rank;
  final PlayerStats stats;
  final String metric;
  final bool stacked;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = rank == 1
        ? AppColors.yellow
        : rank == 2
        ? AppColors.disabledContainer
        : AppColors.background;
    final name = Text(
      stats.player.name,
      textAlign: TextAlign.center,
      style: AppType.bodyStrong,
    );
    return Semantics(
      key: ValueKey('leaderboard-podium-${stats.player.id}'),
      container: true,
      button: true,
      enabled: true,
      label: 'Posizione $rank: ${stats.player.name}. $metric.',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: stacked
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.panel),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: FittedBox(
                              child: Text('$rank', style: AppType.screen),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stats.player.name, style: AppType.player),
                              Text(metric, style: AppType.bodyStrong),
                              RankingBadges(badges: stats.badges),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rank == 1)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Icon(
                            Icons.emoji_events,
                            color: AppColors.ink,
                            size: 28,
                          ),
                        ),
                      PlayerAvatar(
                        name: stats.player.name,
                        size: rank == 1 ? 56 : 48,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                        child: name,
                      ),
                      Text(
                        metric,
                        style: AppType.bodyStrong,
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(3, 8, 3, 12),
                        child: RankingBadges(badges: stats.badges),
                      ),
                      Container(
                        width: double.infinity,
                        height: rank == 1
                            ? 84
                            : rank == 2
                            ? 66
                            : 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: AppColors.divider),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        child: Text('$rank', style: AppType.event),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
