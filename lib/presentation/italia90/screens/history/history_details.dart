import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/game_match.dart';
import '../../../../models/player.dart';
import '../../../../services/stats_service.dart';
import '../../theme/italia90_tokens.dart';

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
            _DetailRow(label: 'Data e ora', value: '$date · $time'),
            _DetailRow(
              label: 'Formato',
              value: match.isRivalry ? 'Rivalita · $mode' : mode,
            ),
            _DetailRow(label: 'Squadra 1', value: '$team1  ${match.t1Score}'),
            _DetailRow(label: 'Squadra 2', value: '$team2  ${match.t2Score}'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('match-details-delete'),
                    onPressed: () =>
                        Navigator.of(context).pop(HistoryMatchAction.delete),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Elimina'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const ValueKey('match-details-edit'),
                    onPressed: () =>
                        Navigator.of(context).pop(HistoryMatchAction.edit),
                    icon: const Icon(Icons.edit),
                    label: const Text('Correggi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 96, child: Text(label, style: Italia90.caption)),
        Expanded(
          child: Text(
            value,
            style: Italia90.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
