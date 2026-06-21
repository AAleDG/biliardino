import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';

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
    final state = context.watch<AppState>();
    final board = state.leaderboard();
    final ranked = board.where((s) => s.games > 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('CLASSIFICA')),
      body: ranked.isEmpty
          ? const _Empty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _Podium(top: ranked.take(3).toList(), anim: _ctrl),
                if (ranked.length > 3) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel('CLASSIFICA COMPLETA'),
                  const SizedBox(height: 8),
                  ...ranked.sublist(3).asMap().entries.map(
                        (e) => _LeaderRow(
                          rank: e.key + 4,
                          stats: e.value,
                          anim: _ctrl,
                          delay: 0.5 + math.min(e.key, 8) * 0.05,
                        ),
                      ),
                ],
              ],
            ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top, required this.anim});

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
              blockHeight: 84,
              color: const Color(0xFFB8C5D6),
              stats: second,
              anim: anim,
              entryDelay: 0.18,
            ),
          ),
          Expanded(
            child: _PodiumColumn(
              rank: 1,
              blockHeight: 128,
              color: NttColors.warning,
              stats: first,
              anim: anim,
              entryDelay: 0.0,
              isWinner: true,
            ),
          ),
          Expanded(
            child: _PodiumColumn(
              rank: 3,
              blockHeight: 60,
              color: const Color(0xFFCD7F32),
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
    required this.color,
    required this.stats,
    required this.anim,
    required this.entryDelay,
    this.isWinner = false,
  });

  final int rank;
  final double blockHeight;
  final Color color;
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
                      Icon(
                        Icons.emoji_events,
                        color: color,
                        size: 22,
                        shadows: [Shadow(color: color, blurRadius: 14)],
                      ),
                    if (isWinner) const SizedBox(height: 4),
                    Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        PlayerAvatar(
                          name: s.player.name,
                          size: isWinner ? 66 : 52,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: NttColors.surfaceDark,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '$rank',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                          color: NttColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.points} pt',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: blockHeight * blockAnim.value,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.55),
                    color.withOpacity(0.10),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                border: Border.all(
                  color: color.withOpacity(0.55),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Opacity(
                  opacity: blockAnim.value,
                  child: Text(
                    '$rank°',
                    style: TextStyle(
                      color: NttColors.textPrimary,
                      fontSize: isWinner ? 30 : 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$rank',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: NttColors.textFaint,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PlayerAvatar(name: stats.player.name, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.player.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${stats.wins}V · ${stats.losses}P · ${stats.games} partite',
                      style: const TextStyle(
                        color: NttColors.textFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${stats.points}',
                style: const TextStyle(
                  color: NttColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
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
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: NttColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 3,
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.leaderboard, size: 64, color: NttColors.textFaint),
              SizedBox(height: 16),
              Text(
                'Nessuna partita giocata',
                style: TextStyle(
                  color: NttColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Registra una partita per vedere la classifica.',
                textAlign: TextAlign.center,
                style: TextStyle(color: NttColors.textMuted),
              ),
            ],
          ),
        ),
      );
}
