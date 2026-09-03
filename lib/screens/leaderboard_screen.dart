import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/leaderboard/leaderboard_cubit.dart';
import '../cubits/leaderboard/leaderboard_state.dart';
import '../models/player_badge.dart';
import '../models/player_stats.dart';
import '../services/csv_share_service.dart';
import '../services/leaderboard_csv_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import 'player_profile_screen.dart';

void _openPlayerProfile(BuildContext context, String playerId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlayerProfileScreen(playerId: playerId),
    ),
  );
}

class _Hud {
  _Hud._();
  static const cyan = Color(0xFF28E0FF);
  static const warm = Color(0xFFFFB703);
  static const text = Color(0xFFCDEEFF);
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final reduceMotion = shouldReduceMotion();
    _ctrl = AnimationController(
      vsync: this,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 1300),
    );
    if (reduceMotion) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        final rankedByPoints = state.stats.where((s) => s.games > 0).toList();
        final rankedByGoals =
            state.stats.where((s) => s.goalsScored > 0).toList()..sort((a, b) {
              final byGoals = b.goalsScored.compareTo(a.goalsScored);
              if (byGoals != 0) return byGoals;
              final byGames = b.games.compareTo(a.games);
              if (byGames != 0) return byGames;
              return a.player.name.toLowerCase().compareTo(
                b.player.name.toLowerCase(),
              );
            });

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'CLASSIFICA',
                style: TextStyle(
                  color: _Hud.cyan,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 5,
                  shadows: [Shadow(color: _Hud.cyan, blurRadius: 14)],
                ),
              ),
              actions: [
                Builder(
                  builder: (buttonContext) {
                    return IconButton(
                      key: const ValueKey('leaderboard-export-csv'),
                      icon: const Icon(Icons.ios_share),
                      tooltip: 'Esporta CSV',
                      onPressed: rankedByPoints.isEmpty
                          ? null
                          : () => _shareLeaderboardCsv(
                              context: buttonContext,
                              ranked: rankedByPoints,
                            ),
                    );
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _ScanlinePainter()),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _Hud.cyan.withValues(alpha: 0.18),
                          ),
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                        child: const TabBar(
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: _Hud.cyan,
                          unselectedLabelColor: _Hud.text,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            color: Color(0x1828E0FF),
                          ),
                          tabs: [
                            Tab(text: 'Generale'),
                            Tab(text: 'Marcatori'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _LeaderboardPane(
                            ranked: rankedByPoints,
                            anim: _ctrl,
                            sectionLabel: 'CLASSIFICA COMPLETA',
                            podiumMetric: (stats) => '${stats.points} pt',
                            rowMetric: (stats) => '${stats.points}',
                            rowDetail: (stats) =>
                                '${stats.wins}V · ${stats.losses}P · ${stats.games} partite',
                            emptyTitle: 'Nessuna partita giocata',
                            emptyDescription:
                                'Registra una partita per vedere la classifica.',
                          ),
                          _LeaderboardPane(
                            ranked: rankedByGoals,
                            anim: _ctrl,
                            sectionLabel: 'CLASSIFICA MARCATORI',
                            podiumMetric: (stats) => '${stats.goalsScored} gol',
                            rowMetric: (stats) => '${stats.goalsScored}',
                            rowDetail: (stats) =>
                                '${stats.games} partite · ${stats.wins} vittorie',
                            emptyTitle: 'Nessun marcatore disponibile',
                            emptyDescription:
                                'I gol compariranno qui dalle partite salvate con assegnazione marcatore.',
                            emptyIcon: Icons.sports_soccer,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _shareLeaderboardCsv({
  required BuildContext context,
  required List<PlayerStats> ranked,
}) async {
  try {
    final csv = LeaderboardCsvService.build(ranked);
    await CsvShareService.platform().shareCsv(
      csv: csv,
      fileName: 'classifica-biliardino.csv',
      subject: 'Classifica Biliardino',
      text: 'Classifica Biliardino in CSV',
      sharePositionOrigin: _sharePositionOrigin(context),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('CSV pronto per la condivisione.')),
      );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Impossibile esportare il CSV: $error')),
      );
  }
}

Rect? _sharePositionOrigin(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox) {
    return null;
  }
  final origin = renderObject.localToGlobal(Offset.zero);
  return origin & renderObject.size;
}

class _LeaderboardPane extends StatelessWidget {
  const _LeaderboardPane({
    required this.ranked,
    required this.anim,
    required this.sectionLabel,
    required this.podiumMetric,
    required this.rowMetric,
    required this.rowDetail,
    required this.emptyTitle,
    required this.emptyDescription,
    this.emptyIcon = Icons.leaderboard,
  });

  final List<PlayerStats> ranked;
  final Animation<double> anim;
  final String sectionLabel;
  final String Function(PlayerStats stats) podiumMetric;
  final String Function(PlayerStats stats) rowMetric;
  final String Function(PlayerStats stats) rowDetail;
  final String emptyTitle;
  final String emptyDescription;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (ranked.isEmpty) {
      return _Empty(
        title: emptyTitle,
        description: emptyDescription,
        icon: emptyIcon,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _PodiumFrame(
          top: ranked.take(3).toList(),
          anim: anim,
          metricLabel: podiumMetric,
        ),
        if (ranked.length > 3) ...[
          const SizedBox(height: 24),
          _SectionLabel(sectionLabel),
          const SizedBox(height: 10),
          ...ranked
              .sublist(3)
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LeaderRow(
                    rank: entry.key + 4,
                    stats: entry.value,
                    anim: anim,
                    delay: 0.5 + math.min(entry.key, 8) * 0.05,
                    metricLabel: rowMetric,
                    detailLabel: rowDetail,
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _PodiumFrame extends StatelessWidget {
  const _PodiumFrame({
    required this.top,
    required this.anim,
    required this.metricLabel,
  });

  final List<PlayerStats> top;
  final Animation<double> anim;
  final String Function(PlayerStats stats) metricLabel;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final narrow = MediaQuery.sizeOf(context).width < 400;
    if (largeText || narrow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in top.asMap().entries) ...[
            _PodiumColumn(
              rank: entry.key + 1,
              blockHeight: 82,
              stats: entry.value,
              anim: anim,
              entryDelay: entry.key * 0.12,
              metricLabel: metricLabel,
              isWinner: entry.key == 0,
            ),
            if (entry.key < top.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    final first = top.isNotEmpty ? top[0] : null;
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;

    return SizedBox(
      height: 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumColumn(
              rank: 2,
              blockHeight: 106,
              stats: second,
              anim: anim,
              entryDelay: 0.18,
              metricLabel: metricLabel,
            ),
          ),
          Expanded(
            child: _PodiumColumn(
              rank: 1,
              blockHeight: 144,
              stats: first,
              anim: anim,
              entryDelay: 0.0,
              metricLabel: metricLabel,
              isWinner: true,
            ),
          ),
          Expanded(
            child: _PodiumColumn(
              rank: 3,
              blockHeight: 82,
              stats: third,
              anim: anim,
              entryDelay: 0.32,
              metricLabel: metricLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.rank,
    required this.blockHeight,
    required this.stats,
    required this.anim,
    required this.entryDelay,
    required this.metricLabel,
    this.isWinner = false,
  });

  final int rank;
  final double blockHeight;
  final PlayerStats? stats;
  final Animation<double> anim;
  final double entryDelay;
  final String Function(PlayerStats stats) metricLabel;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const SizedBox.shrink();
    }
    final s = stats!;
    final accent = hudColorForName(s.player.name);
    final blockAnim = CurvedAnimation(
      parent: anim,
      curve: Interval(
        entryDelay,
        math.min(entryDelay + 0.5, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    final headAnim = CurvedAnimation(
      parent: anim,
      curve: Interval(
        entryDelay + 0.15,
        math.min(entryDelay + 0.55, 1.0),
        curve: Curves.easeOut,
      ),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Opacity(
              opacity: headAnim.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - headAnim.value)),
                child: Semantics(
                  key: ValueKey('leaderboard-podium-${s.player.id}'),
                  container: true,
                  button: true,
                  enabled: true,
                  label:
                      'Posizione $rank: ${s.player.name}. ${metricLabel(s)}.',
                  onTap: () => _openPlayerProfile(context, s.player.id),
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: () => _openPlayerProfile(context, s.player.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          if (isWinner)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Icon(
                                Icons.emoji_events_outlined,
                                color: _Hud.warm,
                                size: 22,
                                shadows: [
                                  Shadow(color: _Hud.warm, blurRadius: 14),
                                ],
                              ),
                            ),
                          _HudAvatar(
                            name: s.player.name,
                            rank: rank,
                            winner: isWinner,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              s.player.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _Hud.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metricLabel(s),
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (s.badges.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: s.badges
                                  .take(2)
                                  .map(_PodiumBadgeChip.new)
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: blockHeight * blockAnim.value,
              width: double.infinity,
              child: Opacity(
                opacity: blockAnim.value,
                child: _PodiumBar(
                  label: '$rank°',
                  accent: accent,
                  isWinner: isWinner,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PodiumBar extends StatelessWidget {
  const _PodiumBar({
    required this.label,
    required this.accent,
    required this.isWinner,
  });

  final String label;
  final Color accent;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 12),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.22),
                  accent.withValues(alpha: 0.03),
                ],
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: isWinner ? 28 : 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                shadows: [Shadow(color: accent, blurRadius: 12)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 4,
          right: 4,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.55),
                  blurRadius: 22,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HudAvatar extends StatelessWidget {
  const _HudAvatar({
    required this.name,
    required this.rank,
    required this.winner,
  });

  final String name;
  final int rank;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final accent = hudColorForName(name);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final size = winner ? 60.0 : 48.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 1.5),
          ),
          child: Text(
            initial,
            style: TextStyle(
              color: accent,
              fontSize: winner ? 24 : 19,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              border: Border.all(color: NttColors.surfaceDark, width: 2),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: NttColors.surfaceDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.stats,
    required this.anim,
    required this.delay,
    required this.metricLabel,
    required this.detailLabel,
  });

  final int rank;
  final PlayerStats stats;
  final Animation<double> anim;
  final double delay;
  final String Function(PlayerStats stats) metricLabel;
  final String Function(PlayerStats stats) detailLabel;

  @override
  Widget build(BuildContext context) {
    final rowAnim = CurvedAnimation(
      parent: anim,
      curve: Interval(
        delay,
        math.min(delay + 0.25, 1.0),
        curve: Curves.easeOut,
      ),
    );
    return AnimatedBuilder(
      animation: rowAnim,
      builder: (_, child) {
        final t = rowAnim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Semantics(
        key: ValueKey('leaderboard-row-${stats.player.id}'),
        container: true,
        button: true,
        enabled: true,
        label:
            'Posizione $rank: ${stats.player.name}. '
            '${metricLabel(stats)}. ${detailLabel(stats)}.',
        onTap: () => _openPlayerProfile(context, stats.player.id),
        child: ExcludeSemantics(
          child: InkWell(
            onTap: () => _openPlayerProfile(context, stats.player.id),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _Hud.cyan.withValues(alpha: 0.22)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _Hud.cyan.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text(
                      '$rank',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _Hud.text.withValues(alpha: 0.82),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  PlayerAvatar(name: stats.player.name, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.player.name,
                          style: const TextStyle(
                            color: _Hud.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          detailLabel(stats),
                          style: TextStyle(
                            color: _Hud.text.withValues(alpha: 0.78),
                            fontSize: 12,
                          ),
                        ),
                        if (stats.badges.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: stats.badges
                                .take(3)
                                .map(_RowBadgeChip.new)
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Builder(
                    builder: (_) {
                      final accent = hudColorForName(stats.player.name);
                      return Text(
                        metricLabel(stats),
                        style: TextStyle(
                          color: accent,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: accent, blurRadius: 10)],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          color: _Hud.text,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _PodiumBadgeChip extends StatelessWidget {
  const _PodiumBadgeChip(this.badge);

  final PlayerBadge badge;

  @override
  Widget build(BuildContext context) {
    final tone = _badgeTone(badge.code);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          color: tone,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RowBadgeChip extends StatelessWidget {
  const _RowBadgeChip(this.badge);

  final PlayerBadge badge;

  @override
  Widget build(BuildContext context) {
    final tone = _badgeTone(badge.code);
    return Tooltip(
      message: badge.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tone.withValues(alpha: 0.32)),
        ),
        child: Text(
          badge.label,
          style: TextStyle(
            color: tone,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Color _badgeTone(String code) {
  switch (code) {
    case 'leader':
      return _Hud.warm;
    case 'bomber':
      return const Color(0xFFFF8A4C);
    case 'grinder':
      return const Color(0xFF9AD1FF);
    case 'dominant':
      return const Color(0xFF7CFFB2);
    case 'streak':
      return const Color(0xFFFF6B6B);
    case 'rivalry':
      return const Color(0xFFFF9F1C);
    default:
      return _Hud.cyan;
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.description,
    this.icon = Icons.leaderboard,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: _Hud.cyan,
              shadows: const [Shadow(color: _Hud.cyan, blurRadius: 18)],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: _Hud.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _Hud.text, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _Hud.cyan.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
