import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/game_match.dart';
import '../../../../models/player.dart';
import '../../../../services/stats_service.dart';
import '../../theme/italia90_tokens.dart';

/// Match card used by the grouped history list.
class HistoryMatchCard extends StatelessWidget {
  const HistoryMatchCard({
    super.key,
    required this.match,
    required this.players,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final GameMatch match;
  final List<Player> players;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final names1 = match.team1
        .map((id) => StatsService.playerName(players, id))
        .toList();
    final names2 = match.team2
        .map((id) => StatsService.playerName(players, id))
        .toList();
    final baseMode = match.mode == MatchMode.oneVsOne ? '1v1' : '2v2';
    final mode = match.isRivalry ? 'Rivalità · $baseMode' : baseMode;
    final winnerColor = match.winningTeam == 1
        ? Italia90.teamOne
        : Italia90.teamTwo;

    return Card(
      key: ValueKey('history-match-${match.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Italia90.panelRadius),
        side: BorderSide(color: Italia90.outline.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onOpen,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: winnerColor, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
            child: Column(
              children: [
                _MetaRow(
                  timeLabel: DateFormat('HH:mm').format(match.playedAt),
                  modeLabel: mode,
                  isRivalry: match.isRivalry,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
                const SizedBox(height: 8),
                _TeamResultLine(
                  semanticKey: ValueKey('history-team-${match.id}-team-1'),
                  team: ItaliaTeam.one,
                  names: names1,
                  score: match.t1Score,
                  isWinner: match.winningTeam == 1,
                ),
                const SizedBox(height: 4),
                _TeamResultLine(
                  semanticKey: ValueKey('history-team-${match.id}-team-2'),
                  team: ItaliaTeam.two,
                  names: names2,
                  score: match.t2Score,
                  isWinner: match.winningTeam == 2,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.timeLabel,
    required this.modeLabel,
    required this.isRivalry,
    required this.onEdit,
    required this.onDelete,
  });

  final String timeLabel;
  final String modeLabel;
  final bool isRivalry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 260 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final menu = SizedBox(
        width: Italia90.touch,
        height: Italia90.touch,
        child: PopupMenuButton<_CardAction>(
          tooltip: 'Azioni partita',
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case _CardAction.edit:
                onEdit();
              case _CardAction.delete:
                onDelete();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _CardAction.edit,
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Correggi'),
              ),
            ),
            PopupMenuItem(
              value: _CardAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Elimina'),
              ),
            ),
          ],
        ),
      );
      final time = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 18, color: Italia90.muted),
          const SizedBox(width: 5),
          Text(
            timeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Italia90.caption.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      );
      final mode = DecoratedBox(
        decoration: BoxDecoration(
          color: isRivalry ? Italia90.brickContainer : Italia90.subtle,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            modeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Italia90.caption.copyWith(
              color: isRivalry ? Italia90.primary : Italia90.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: time),
                ),
                menu,
              ],
            ),
            Align(alignment: Alignment.center, child: mode),
          ],
        );
      }
      return Row(
        children: [
          SizedBox(width: 88, child: time),
          Expanded(child: Center(child: mode)),
          menu,
        ],
      );
    },
  );
}

enum _CardAction { edit, delete }

class _TeamResultLine extends StatelessWidget {
  const _TeamResultLine({
    required this.semanticKey,
    required this.team,
    required this.names,
    required this.score,
    required this.isWinner,
  });

  final Key semanticKey;
  final ItaliaTeam team;
  final List<String> names;
  final int score;
  final bool isWinner;

  @override
  Widget build(BuildContext context) => Semantics(
    key: semanticKey,
    container: true,
    label:
        '${team.label}: ${names.join(' / ')}, punteggio $score'
        '${isWinner ? ', vittoria' : ''}',
    child: ExcludeSemantics(
      child: Row(
        children: [
          _TeamMarker(team: team, isWinner: isWinner),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              names.join(' / '),
              style: Italia90.body.copyWith(
                color: isWinner ? Italia90.ink : Italia90.muted,
                fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: math.max(40.0, _scoreWidth(context, score)),
            child: Text(
              '$score',
              textAlign: TextAlign.right,
              maxLines: 1,
              style: Italia90.heading.copyWith(
                color: isWinner ? team.onNeutralSurface : Italia90.muted,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  double _scoreWidth(BuildContext context, int value) {
    final painter = TextPainter(
      text: TextSpan(text: '$value', style: Italia90.heading),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout();
    final width = painter.width + 8;
    painter.dispose();
    return width;
  }
}

class _TeamMarker extends StatelessWidget {
  const _TeamMarker({required this.team, required this.isWinner});

  final ItaliaTeam team;
  final bool isWinner;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 14,
    height: 14,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: isWinner ? team.color : team.container,
        shape: BoxShape.circle,
        border: Border.all(color: team.color, width: isWinner ? 1 : 2),
      ),
    ),
  );
}
