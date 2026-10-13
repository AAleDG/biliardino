import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../models/ranking_stats.dart';
import '../../models/player_badge.dart';
import '../../theme/app_theme.dart';
import 'ranking_identity.dart';
import 'ranking_podium_artwork.dart';
import 'ranking_badges.dart';

/// Shared podium for points and scorers; opens profiles through its owner.
class RankingPodium extends StatefulWidget {
  const RankingPodium({
    super.key,
    required this.top,
    required this.metricLabel,
    required this.onOpen,
  });
  final List<RankingStats> top;
  final String Function(RankingStats) metricLabel;
  final ValueChanged<String> onOpen;
  @override
  State<RankingPodium> createState() => _RankingPodiumState();
}

class _RankingPodiumState extends State<RankingPodium>
    with SingleTickerProviderStateMixin, MotionAwareState {
  // Rendering and content-fit checks share the approved per-rank anchors.
  static const _slots = [
    (
      left: 143.0,
      top: 14.0,
      width: 117.0,
      contentBottom: 200.0,
      rankTop: 220.0,
    ),
    (left: 19.0, top: 75.0, width: 124.0, contentBottom: 221.0, rankTop: 241.0),
    (
      left: 260.0,
      top: 90.0,
      width: 123.0,
      contentBottom: 228.0,
      rankTop: 247.0,
    ),
  ];
  late final AnimationController _entry;
  bool _played = false;
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _imageListener = ImageStreamListener((
    info,
    _,
  ) {
    if (!mounted) {
      info.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = info;
    });
  });
  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: AppMotion.podium);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      'design/south-africa-2010/assets/live-r1/live-scene.png',
    ).resolve(createLocalImageConfiguration(context));
    if (_stream?.key != stream.key) {
      _stream?.removeListener(_imageListener);
      _stream = stream..addListener(_imageListener);
    }
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
    _stream?.removeListener(_imageListener);
    _image?.dispose();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!TickerMode.valuesOf(context).enabled && !_played) {
        return Transform.translate(
          offset: const Offset(0, 12),
          child: const SizedBox.shrink(),
        );
      }
      final entries = widget.top.take(3).toList();
      if (entries.isEmpty) return const SizedBox.shrink();
      final width = constraints.maxWidth.clamp(0.0, 520.0);
      final scale = width / 402;
      final stacked =
          width < 350 ||
          MediaQuery.sizeOf(context).height < 450 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
          entries.asMap().entries.any(
            (entry) => !_fitsEntry(context, entry.value, entry.key, scale),
          );
      final content = stacked
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _place(entries[i], i, stacked: true),
                    ),
                ],
              ),
            )
          : Center(
              child: SizedBox(
                width: width,
                height: 316 * scale,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: RankingPodiumArtwork(scene: _image?.image),
                        ),
                      ),
                    ),
                    for (final i in [1, 0, 2])
                      Positioned(
                        left: _slots[i].left * scale,
                        top: _slots[i].top * scale,
                        width: _slots[i].width * scale,
                        bottom: 0,
                        child: i < entries.length
                            ? _place(entries[i], i, stacked: false)
                            : const SizedBox.shrink(),
                      ),
                    for (final i in [1, 0, 2])
                      Positioned(
                        left: _slots[i].left * scale,
                        top: _slots[i].rankTop * scale,
                        width: _slots[i].width * scale,
                        child: IgnorePointer(
                          child: ExcludeSemantics(
                            child: Text(
                              '${i + 1}',
                              key: ValueKey('podium-block-${i + 1}'),
                              textAlign: TextAlign.center,
                              textScaler: TextScaler.noScaling,
                              style: AppType.event.copyWith(
                                fontSize: 56 * scale,
                                color: i == 0
                                    ? AppColors.ink
                                    : AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            painter: RankingPodiumArtwork(
                              scene: _image?.image,
                              foreground: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
      return AnimatedBuilder(
        animation: _entry,
        builder: (_, child) => Transform.translate(
          offset: Offset(
            0,
            12 * (1 - Curves.easeOutCubic.transform(_entry.value)),
          ),
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            if (!stacked)
              for (var i = 0; i < entries.length; i++)
                if (entries[i].badges.any((badge) => !_isPodiumBadge(badge)))
                  SizedBox(
                    width: width,
                    child: _AdditionalAwards(stats: entries[i], rank: i + 1),
                  ),
          ],
        ),
      );
    },
  );

  bool _fitsEntry(
    BuildContext context,
    RankingStats stats,
    int index,
    double scale,
  ) {
    final slot = _slots[index];
    final width = slot.width * scale;
    double heightOf(String text, TextStyle style, double availableWidth) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      )..layout(maxWidth: availableWidth);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final style = AppType.bodyStrong.copyWith(height: 1.2);
    final badges = _podiumBadges(stats);
    final badgesHeight = badges.fold<double>(
      0,
      (sum, badge) =>
          sum +
          heightOf(
            badge.label,
            RankingBadges.labelStyle,
            width - RankingBadges.labelWidthInset,
          ) +
          RankingBadges.contentPadding.vertical +
          RankingBadges.spacing,
    );
    final avatarHeight =
        (index == 0 ? 50.0 : 46.0) * (stats.memberNames.length == 1 ? 1 : .72);
    final contentHeight =
        (index == 0 ? 32 : 0) +
        avatarHeight +
        6 +
        heightOf(stats.name, style, width) +
        heightOf(widget.metricLabel(stats), style, width) +
        4 +
        badgesHeight -
        (badges.isEmpty ? 0 : RankingBadges.spacing);
    final availableHeight = (slot.contentBottom - slot.top) * scale;
    return contentHeight <= availableHeight;
  }

  Widget _place(RankingStats stats, int index, {required bool stacked}) =>
      _PodiumPlace(
        rank: index + 1,
        stats: stats,
        metric: widget.metricLabel(stats),
        stacked: stacked,
        onTap: () => widget.onOpen(stats.id),
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
  final RankingStats stats;
  final String metric;
  final bool stacked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badges = stacked ? stats.badges : _podiumBadges(stats);
    return Semantics(
      key: ValueKey('leaderboard-podium-${stats.id}'),
      sortKey: OrdinalSortKey(rank.toDouble()),
      container: true,
      button: true,
      enabled: true,
      hint: 'Apri il profilo',
      label:
          'Posizione $rank: ${stats.name}. $metric. ${badges.map((b) => b.label).join(', ')}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: stacked ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.panel),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.panel),
            child: stacked
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '$rank',
                            style: AppType.section.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stats.name, style: AppType.player),
                              Text(metric, style: AppType.bodyStrong),
                              RankingBadges(badges: badges),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rank == 1) ...[
                        const Icon(
                          Icons.emoji_events,
                          color: AppColors.yellow,
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                      ],
                      RankingIdentity(
                        names: stats.memberNames,
                        size: rank == 1 ? 50 : 46,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stats.name,
                        textAlign: TextAlign.center,
                        style: AppType.bodyStrong.copyWith(height: 1.2),
                      ),
                      Text(
                        metric,
                        textAlign: TextAlign.center,
                        style: AppType.bodyStrong.copyWith(height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      RankingBadges(badges: badges),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Keep the podium fit calculation and inline rendering on the same policy.
bool _isPodiumBadge(PlayerBadge badge) =>
    badge.code == 'leader' || badge.code == 'bomber';

List<PlayerBadge> _podiumBadges(RankingStats stats) =>
    stats.badges.where(_isPodiumBadge).toList(growable: false);

/// Earned ribbons that need more room stay visible below the podium, by entrant.
class _AdditionalAwards extends StatelessWidget {
  const _AdditionalAwards({required this.stats, required this.rank});
  final RankingStats stats;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final badges = stats.badges
        .where((badge) => !_isPodiumBadge(badge))
        .toList(growable: false);
    return Semantics(
      container: true,
      // Keep all profile actions together before the supporting award groups.
      sortKey: OrdinalSortKey(100 + rank.toDouble()),
      label:
          'Riconoscimenti di ${stats.name}: ${badges.map((badge) => badge.label).join(', ')}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.panel),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(stats.name, style: AppType.player),
                  const SizedBox(height: 8),
                  RankingBadges(badges: badges),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
