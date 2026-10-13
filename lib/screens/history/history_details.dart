part of '../history_screen.dart';

enum _MatchAction { edit, delete }

class _MatchDetailsSheet extends StatelessWidget {
  const _MatchDetailsSheet({required this.match, required this.players});

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
        20,
        12,
        20,
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
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dettagli partita',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            _MatchDetailRow(label: 'Data e ora', value: '$date · $time'),
            _MatchDetailRow(
              label: 'Formato',
              value: match.isRivalry ? 'Rivalità · $mode' : mode,
            ),
            _MatchDetailRow(
              label: 'Squadra 1',
              value: '$team1  ${match.t1Score}',
            ),
            _MatchDetailRow(
              label: 'Squadra 2',
              value: '$team2  ${match.t2Score}',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('match-details-delete'),
                    onPressed: () =>
                        Navigator.of(context).pop(_MatchAction.delete),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Elimina'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const ValueKey('match-details-edit'),
                    onPressed: () =>
                        Navigator.of(context).pop(_MatchAction.edit),
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

class _MatchDetailRow extends StatelessWidget {
  const _MatchDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
