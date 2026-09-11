import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';
import 'live_match_artwork.dart';

class LiveTeamCard extends StatelessWidget {
  const LiveTeamCard({
    super.key,
    required this.team,
    required this.names,
    required this.score,
    required this.enabled,
    required this.onAdd,
    required this.onUndo,
  });
  final int team, score;
  final List<String> names;
  final bool enabled;
  final VoidCallback onAdd, onUndo;
  @override
  Widget build(BuildContext context) {
    final color = team == 1 ? AppColors.teamOne : AppColors.teamTwo;
    const foreground = AppColors.onPrimary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: team == 1
                  ? LiveMatchPaints.blue
                  : LiveMatchPaints.orangeHeader,
            ),
            child: Text(
              'SQUADRA $team',
              textAlign: TextAlign.center,
              style: AppType.section.copyWith(color: foreground),
            ),
          ),
          for (final name in names)
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color.withValues(alpha: .15)),
                ),
              ),
              child: Row(
                children: [
                  PlayerAvatar(name: name, size: 30, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, style: AppType.bodyStrong)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    key: ValueKey('score-add-team-$team'),
                    container: true,
                    button: true,
                    enabled: enabled,
                    label:
                        'Aggiungi un goal a SQUADRA $team. Punteggio attuale $score.',
                    onTap: enabled ? onAdd : null,
                    child: ExcludeSemantics(
                      child: FilledButton(
                        onPressed: enabled ? onAdd : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          backgroundColor: color.withValues(alpha: .12),
                          foregroundColor: team == 1 ? color : AppColors.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '+1',
                          style: AppType.section.copyWith(fontSize: 30),
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  key: ValueKey('score-undo-team-$team'),
                  container: true,
                  button: true,
                  enabled: enabled && score > 0,
                  label: 'Annulla ultimo goal di SQUADRA $team',
                  onTap: enabled && score > 0 ? onUndo : null,
                  child: ExcludeSemantics(
                    child: IconButton(
                      tooltip: 'Annulla ultimo goal di SQUADRA $team',
                      onPressed: enabled && score > 0 ? onUndo : null,
                      icon: const Icon(Icons.undo, size: 22),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
