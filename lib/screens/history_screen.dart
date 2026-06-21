import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/game_match.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  String? _filterId;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    final matches = _filterId == null
        ? state.matchesSorted
        : state.matchesForPlayer(_filterId!);

    return Scaffold(
      appBar: AppBar(title: const Text('STORICO')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DropdownButtonFormField<String?>(
              initialValue: _filterId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filtra per giocatore',
                prefixIcon: Icon(Icons.filter_alt_outlined, size: 20),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tutti i giocatori'),
                ),
                ...state.players.map(
                  (p) => DropdownMenuItem<String?>(
                    value: p.id,
                    child: Text(p.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _filterId = v),
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? const _Empty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
                    itemCount: matches.length,
                    itemBuilder: (_, i) => _MatchTimelineTile(
                      match: matches[i],
                      state: state,
                      anim: _ctrl,
                      delay: math.min(i, 8) * 0.06,
                      isFirst: i == 0,
                      isLast: i == matches.length - 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatchTimelineTile extends StatelessWidget {
  const _MatchTimelineTile({
    required this.match,
    required this.state,
    required this.anim,
    required this.delay,
    required this.isFirst,
    required this.isLast,
  });

  final GameMatch match;
  final AppState state;
  final Animation<double> anim;
  final double delay;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final winColor =
        match.winningTeam == 1 ? NttColors.team1 : NttColors.team2;
    final tileAnim = CurvedAnimation(
      parent: anim,
      curve: Interval(
        delay,
        math.min(delay + 0.3, 1.0),
        curve: Curves.easeOut,
      ),
    );

    return IntrinsicHeight(
      child: AnimatedBuilder(
        animation: tileAnim,
        builder: (_, child) {
          final t = tileAnim.value;
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - t)),
              child: child,
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TimelineRail(isFirst: isFirst, isLast: isLast, dotColor: winColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
                child: _MatchCard(
                  match: match,
                  state: state,
                  winColor: winColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({
    required this.isFirst,
    required this.isLast,
    required this.dotColor,
  });

  final bool isFirst;
  final bool isLast;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Stack(
        children: [
          if (!isFirst)
            Positioned(
              top: 0,
              bottom: null,
              left: 18,
              child: Container(
                width: 2,
                height: 22,
                color: NttColors.accent.withOpacity(0.25),
              ),
            ),
          Positioned(
            top: 22,
            bottom: 0,
            left: 18,
            child: Container(
              width: 2,
              color: isLast
                  ? Colors.transparent
                  : NttColors.accent.withOpacity(0.25),
            ),
          ),
          Positioned(
            top: 18,
            left: 11,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border:
                    Border.all(color: NttColors.surfaceDark, width: 3),
                boxShadow: [
                  BoxShadow(color: dotColor.withOpacity(0.75), blurRadius: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.state,
    required this.winColor,
  });

  final GameMatch match;
  final AppState state;
  final Color winColor;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM · HH:mm');
    final t1Names = match.team1.map(state.playerName).toList();
    final t2Names = match.team2.map(state.playerName).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: winColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 12, color: NttColors.textFaint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        df.format(match.playedAt),
                        style: const TextStyle(
                          color: NttColors.textFaint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: winColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: winColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        'VINCE S${match.winningTeam}',
                        style: TextStyle(
                          color: winColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TeamLine(
                  label: 'S1',
                  color: NttColors.team1,
                  names: t1Names,
                  score: match.t1Score,
                  isWinner: match.winningTeam == 1,
                ),
                const SizedBox(height: 4),
                _TeamLine(
                  label: 'S2',
                  color: NttColors.team2,
                  names: t2Names,
                  score: match.t2Score,
                  isWinner: match.winningTeam == 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({
    required this.label,
    required this.color,
    required this.names,
    required this.score,
    required this.isWinner,
  });

  final String label;
  final Color color;
  final List<String> names;
  final int score;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(isWinner ? 1.0 : 0.18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isWinner ? NttColors.surfaceDark : color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            names.join(' & '),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWinner
                  ? NttColors.textPrimary
                  : NttColors.textMuted,
              fontSize: 14,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$score',
          style: TextStyle(
            color: isWinner ? color : NttColors.textFaint,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.history, size: 64, color: NttColors.textFaint),
            SizedBox(height: 16),
            Text(
              'Nessuna partita',
              style: TextStyle(
                color: NttColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Quando registri partite le vedrai qui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NttColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
