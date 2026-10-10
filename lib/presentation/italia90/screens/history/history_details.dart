import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/game_match.dart';
import '../../../../models/player.dart';
import '../../../../services/stats_service.dart';
import '../../theme/italia90_tokens.dart';
import '../../widgets/design/adaptive_pair.dart';

enum HistoryMatchAction { edit, delete }

/// Details sheet owned by the history feature rather than the page shell.
class HistoryMatchDetailsSheet extends StatelessWidget {
  const HistoryMatchDetailsSheet({
    super.key,
    required this.match,
    required this.players,
  });

  final GameMatch match;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(match.playedAt);
    final time = DateFormat('HH:mm').format(match.playedAt);
    final team1 = match.team1
        .map((id) => StatsService.playerName(players, id))
        .join(' / ');
    final team2 = match.team2
        .map((id) => StatsService.playerName(players, id))
        .join(' / ');
    final mode = match.mode == MatchMode.oneVsOne ? '1v1' : '2v2';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Italia90.page,
        12,
        Italia90.page,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Italia90.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Dettagli partita', style: Italia90.heading),
            const SizedBox(height: 18),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Italia90.panel,
                borderRadius: BorderRadius.circular(Italia90.panelRadius),
                border: Border.all(
                  color: Italia90.outline.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.event_outlined,
                    accentColor: Italia90.primary,
                    label: 'Data e ora',
                    value: '$date · $time',
                  ),
                  const Divider(height: 1, color: Italia90.subtle),
                  _DetailRow(
                    icon: Icons.sports_soccer_outlined,
                    accentColor: Italia90.primary,
                    label: 'Formato',
                    value: match.isRivalry ? 'Rivalita · $mode' : mode,
                  ),
                  const Divider(height: 1, color: Italia90.subtle),
                  _DetailRow(
                    icon: Icons.groups_outlined,
                    accentColor: Italia90.teamOne,
                    label: 'Squadra 1',
                    value: '$team1  ${match.t1Score}',
                  ),
                  const Divider(height: 1, color: Italia90.subtle),
                  _DetailRow(
                    icon: Icons.groups_outlined,
                    accentColor: Italia90.teamTwo,
                    label: 'Squadra 2',
                    value: '$team2  ${match.t2Score}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AdaptivePair(
              first: OutlinedButton.icon(
                key: const ValueKey('match-details-delete'),
                onPressed: () =>
                    Navigator.of(context).pop(HistoryMatchAction.delete),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Elimina'),
              ),
              second: ElevatedButton.icon(
                key: const ValueKey('match-details-edit'),
                onPressed: () =>
                    Navigator.of(context).pop(HistoryMatchAction.edit),
                icon: const Icon(Icons.edit),
                label: const Text('Correggi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.accentColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color accentColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final stacked = largeText || constraints.maxWidth < 300;
      final labelWidget = Text(
        label,
        style: Italia90.body.copyWith(
          color: Italia90.muted,
          fontWeight: FontWeight.w600,
        ),
      );
      final valueWidget = Text(value, style: Italia90.title);
      final textContent = stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, const SizedBox(height: 4), valueWidget],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 96, child: labelWidget),
                const SizedBox(width: 12),
                Expanded(child: valueWidget),
              ],
            );

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(icon, color: accentColor, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: textContent),
          ],
        ),
      );
    },
  );
}
