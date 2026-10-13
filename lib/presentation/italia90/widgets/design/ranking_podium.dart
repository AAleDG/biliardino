import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../models/player_badge.dart';
import '../../../../models/player_stats.dart';
import '../../../../models/team_leaderboard_stats.dart';
import '../../theme/app_theme.dart';
import '../../theme/italia90_tokens.dart';
import '../ranking_recognitions.dart';
import 'ranking_avatar.dart';
import 'ranking_podium_artwork.dart';

/// Data displayed by one place in the reusable Classifica podium.
class RankingPodiumEntry {
  const RankingPodiumEntry({
    required this.id,
    required this.name,
    required this.avatarNames,
    required this.metric,
    required this.badges,
    required this.openId,
  });

  factory RankingPodiumEntry.player(
    PlayerStats stats, {
    required String metric,
  }) {
    return RankingPodiumEntry(
      id: stats.player.id,
      name: stats.player.name,
      avatarNames: [stats.player.name],
      metric: metric,
      badges: stats.badges,
      openId: stats.player.id,
    );
  }

  factory RankingPodiumEntry.team(
    TeamLeaderboardStats stats, {
    required String metric,
  }) {
    return RankingPodiumEntry(
      id: stats.id,
      name: stats.name,
      avatarNames: stats.players.map((player) => player.name).toList(),
      metric: metric,
      badges: stats.badges,
      openId: stats.id,
    );
  }

  final String id;
  final String name;
  final List<String> avatarNames;
  final String metric;
  final List<PlayerBadge> badges;
  final String openId;
}

/// Italia '90 podium used by both the individual and 2vs2 rankings.
class RankingPodium extends StatefulWidget {
  const RankingPodium({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.showArtwork,
  });

  final List<RankingPodiumEntry> entries;
  final ValueChanged<String> onOpen;

  /// Whether to render the optional illustrated podium treatment.
  final bool showArtwork;

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
    if (!visible && _played) {
      settleMotion();
    }
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
      if (!TickerMode.valuesOf(context).enabled && !_played) {
        return Transform.translate(
          offset: const Offset(0, 12),
          child: const SizedBox.shrink(),
        );
      }
      final entries = widget.entries.take(3).toList(growable: false);
      if (entries.isEmpty) return const SizedBox.shrink();

      final width = constraints.maxWidth.clamp(0.0, 520.0);
      final scale = width / 402;
      final stacked =
          width < 350 ||
          MediaQuery.sizeOf(context).height < 450 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final achievements = _collectAchievements(entries);
      final sceneHeight = (widget.showArtwork ? 316 : 260) * scale;
      return AnimatedBuilder(
        animation: _entry,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: const ValueKey('leaderboard-podium'),
              child: stacked
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          for (var i = 0; i < entries.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == entries.length - 1 ? 0 : 12,
                              ),
                              child: _animatedPlace(
                                entries[i],
                                i,
                                stacked: true,
                                showArtwork: widget.showArtwork,
                              ),
                            ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: sceneHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (widget.showArtwork)
                            const Positioned.fill(
                              child: ExcludeSemantics(
                                child: CustomPaint(
                                  painter: RankingPodiumArtwork(),
                                ),
                              ),
                            ),
                          _positionedPlace(entries, 1, scale),
                          _positionedPlace(entries, 0, scale),
                          _positionedPlace(entries, 2, scale),
                          if (widget.showArtwork)
                            const Positioned.fill(
                              child: IgnorePointer(
                                child: ExcludeSemantics(
                                  child: CustomPaint(
                                    painter: RankingPodiumArtwork(
                                      foreground: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: 8),
              _RankingAchievementStrip(achievements: achievements),
            ],
          ],
        ),
      );
    },
  );

  Widget _positionedPlace(
    List<RankingPodiumEntry> entries,
    int index,
    double scale,
  ) {
    if (index >= entries.length) return const SizedBox.shrink();
    final slot = switch (index) {
      0 => (left: 129.0, top: 34.0, width: 144.0, angle: 0.0),
      1 => (left: 12.0, top: 96.0, width: 126.0, angle: -0.035),
      _ => (left: 264.0, top: 96.0, width: 126.0, angle: 0.035),
    };
    return Positioned(
      left: slot.left * scale,
      top: slot.top * scale,
      width: slot.width * scale,
      bottom: 12 * scale,
      child: _animatedPlace(
        entries[index],
        index,
        stacked: false,
        showArtwork: widget.showArtwork,
        scale: scale,
        angle: slot.angle,
      ),
    );
  }

  Widget _animatedPlace(
    RankingPodiumEntry entry,
    int index, {
    required bool stacked,
    required bool showArtwork,
    double scale = 1,
    double angle = 0,
  }) {
    final interval = switch (index) {
      0 => const Interval(0, .72, curve: Curves.easeOutCubic),
      1 => const Interval(.08, .82, curve: Curves.easeOutCubic),
      _ => const Interval(.16, .92, curve: Curves.easeOutCubic),
    };
    final progress = reduceMotion
        ? 1.0
        : interval.transform(_entry.value.clamp(0.0, 1.0));
    final entryWidget = _PodiumPlace(
      rank: index + 1,
      entry: entry,
      stacked: stacked,
      showArtwork: showArtwork,
      scale: scale,
      onTap: () => widget.onOpen(entry.openId),
    );
    return Transform.translate(
      offset: Offset(0, (1 - progress) * (stacked ? 18 : 34)),
      child: Transform.rotate(
        angle: stacked ? 0 : angle * progress,
        child: entryWidget,
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.rank,
    required this.entry,
    required this.stacked,
    required this.showArtwork,
    required this.scale,
    required this.onTap,
  });

  final int rank;
  final RankingPodiumEntry entry;
  final bool stacked;
  final bool showArtwork;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = _rankColor(rank);
    final onCard = rank == 1 ? Italia90.ink : Colors.white;
    final awardSummary = entry.badges.isEmpty
        ? ''
        : ' ${entry.badges.map((badge) => badge.label).join(', ')}.';

    return KeyedSubtree(
      key: ValueKey('leaderboard-winner-${entry.id}'),
      child: Semantics(
        key: ValueKey('leaderboard-podium-${entry.id}'),
        sortKey: OrdinalSortKey(rank.toDouble()),
        container: true,
        button: true,
        enabled: true,
        hint: 'Apri il profilo',
        label: 'Posizione $rank: ${entry.name}. ${entry.metric}.$awardSummary',
        onTap: onTap,
        child: ExcludeSemantics(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                key: ValueKey('leaderboard-podium-card-${entry.id}'),
                color: stacked ? Italia90.panel : cardColor,
                clipBehavior: Clip.antiAlias,
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(stacked ? 8 : 4),
                  side: stacked
                      ? const BorderSide(color: Italia90.outline)
                      : const BorderSide(color: Italia90.ink, width: 2.5),
                ),
                child: InkWell(
                  onTap: onTap,
                  child: stacked
                      ? _stackedContent()
                      : Stack(
                          children: [
                            if (showArtwork && rank == 1)
                              const Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: RankingLaurelArtwork(),
                                  ),
                                ),
                              ),
                            _cardContent(cardColor, onCard),
                          ],
                        ),
                ),
              ),
              if (showArtwork && !stacked)
                Positioned(
                  top: (rank == 1 ? -36 : -56) * scale,
                  left: -8 * scale,
                  right: -8 * scale,
                  height: (rank == 1 ? 114 : 98) * scale,
                  child: IgnorePointer(
                    child: RankingFoosballFigure(
                      key: ValueKey('leaderboard-foosball-figure-$rank'),
                      shirtColor: rank == 3 ? Italia90.red : Italia90.teamOne,
                      compact: rank != 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stackedContent() => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        SizedBox(width: 36, child: Text('$rank', style: Italia90.heading)),
        const SizedBox(width: 12),
        _avatars(40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.name, style: Italia90.title),
              Text(
                entry.metric,
                style: Italia90.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _cardContent(Color cardColor, Color onCard) {
    final avatarSize = (rank == 1 ? 43 : 38) * scale;
    final topPadding = showArtwork ? (rank == 1 ? 80 : 43) : 18;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        6 * scale,
        topPadding * scale,
        6 * scale,
        8 * scale,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _avatars(avatarSize),
                SizedBox(height: 5 * scale),
                Text(
                  '$rank',
                  style: Italia90.display.copyWith(
                    color: onCard,
                    fontSize: (rank == 1 ? 58 : 45) * scale,
                    height: .9,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  entry.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: Italia90.title.copyWith(
                    color: onCard,
                    fontSize: (rank == 1 ? 18 : 14) * scale,
                    height: 1.1,
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4 * scale),
                  height: 1.5 * scale,
                  color: onCard,
                ),
                Text(
                  entry.metric,
                  style: Italia90.title.copyWith(
                    color: rank == 1 ? Italia90.teamOne : onCard,
                    fontSize: 19 * scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatars(double size) {
    final names = entry.avatarNames.take(2).toList(growable: false);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < names.length; i++)
          Transform.translate(
            offset: Offset(i == 0 ? 0 : -size * .14, 0),
            child: RankingAvatar(name: names[i], size: size),
          ),
      ],
    );
  }

  static Color _rankColor(int rank) => switch (rank) {
    1 => Italia90.teamTwo,
    2 => Italia90.teamOne,
    3 => Italia90.red,
    _ => Italia90.primary,
  };
}

class _RankingAchievement {
  const _RankingAchievement({required this.entry, required this.badge});

  final RankingPodiumEntry entry;
  final PlayerBadge badge;
}

List<_RankingAchievement> _collectAchievements(
  List<RankingPodiumEntry> entries,
) {
  final seen = <String>{};
  final achievements = <_RankingAchievement>[];
  for (final entry in entries) {
    for (final badge in entry.badges) {
      if (seen.add(badge.code)) {
        achievements.add(_RankingAchievement(entry: entry, badge: badge));
      }
    }
  }
  return List.unmodifiable(achievements);
}

class _RankingAchievementStrip extends StatelessWidget {
  const _RankingAchievementStrip({required this.achievements});

  final List<_RankingAchievement> achievements;

  @override
  Widget build(BuildContext context) => RankingRecognitions(
    key: const ValueKey('leaderboard-achievements'),
    keyPrefix: 'leaderboard',
    items: [
      for (final achievement in achievements)
        RankingRecognition(
          ownerId: achievement.entry.id,
          ownerName: achievement.entry.name,
          badge: achievement.badge,
        ),
    ],
  );
}
