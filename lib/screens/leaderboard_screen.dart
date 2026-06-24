import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/leaderboard/leaderboard_cubit.dart';
import '../cubits/leaderboard/leaderboard_state.dart';
import '../models/player_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';

class _Hud {
  _Hud._();
  static const cyan = Color(0xFF28E0FF);
  static const magenta = Color(0xFFFF3D9A);
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
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
        final ranked = state.stats.where((s) => s.games > 0).toList();

        return Scaffold(
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
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _ScanlinePainter()),
              ),
              ranked.isEmpty
                  ? const _Empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _PodiumFrame(
                          top: ranked.take(3).toList(),
                          anim: _ctrl,
                        ),
                        if (ranked.length > 3) ...[
                          const SizedBox(height: 24),
                          const _SectionLabel('CLASSIFICA COMPLETA'),
                          const SizedBox(height: 10),
                          ...ranked.sublist(3).asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _LeaderRow(
                                    rank: e.key + 4,
                                    stats: e.value,
                                    anim: _ctrl,
                                    delay:
                                        0.5 + math.min(e.key, 8) * 0.05,
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _PodiumFrame extends StatelessWidget {
  const _PodiumFrame({required this.top, required this.anim});

  final List<PlayerStats> top;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    final first = top.isNotEmpty ? top[0] : null;
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;

    return SizedBox(
      height: 290,
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
            ),
          ),
          Expanded(
            child: _PodiumColumn(
              rank: 1,
              blockHeight: 144,
              stats: first,
              anim: anim,
              entryDelay: 0.0,
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
    this.isWinner = false,
  });

  final int rank;
  final double blockHeight;
  final PlayerStats? stats;
  final Animation<double> anim;
  final double entryDelay;
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
                child: Column(
                  children: [
                    if (isWinner)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(
                          Icons.emoji_events_outlined,
                          color: _Hud.magenta,
                          size: 22,
                          shadows: [
                            Shadow(color: _Hud.magenta, blurRadius: 14),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Hud.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.points} pt',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
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
              border:
                  Border.all(color: NttColors.surfaceDark, width: 2),
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
  });

  final int rank;
  final PlayerStats stats;
  final Animation<double> anim;
  final double delay;

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
                  color: _Hud.text.withValues(alpha: 0.6),
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
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${stats.wins}V · ${stats.losses}P · ${stats.games} partite',
                    style: TextStyle(
                      color: _Hud.text.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Builder(
              builder: (_) {
                final accent = hudColorForName(stats.player.name);
                return Text(
                  '${stats.points}',
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _Hud.text,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.leaderboard,
              size: 64,
              color: _Hud.cyan,
              shadows: [Shadow(color: _Hud.cyan, blurRadius: 18)],
            ),
            SizedBox(height: 16),
            Text(
              'Nessuna partita giocata',
              style: TextStyle(
                color: _Hud.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Registra una partita per vedere la classifica.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _Hud.text, fontSize: 13),
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
