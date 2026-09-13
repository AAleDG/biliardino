import 'package:flutter/material.dart';
import '../../cubits/match_editor/match_edit_draft.dart';
import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';
import '../../widgets/design/profile_artwork.dart' show ProfileCornerSweep;

class DistintaTeamCard extends StatelessWidget {
  const DistintaTeamCard({
    super.key,
    required this.draft,
    required this.number,
    required this.players,
    required this.onScore,
    required this.onEditScore,
    required this.onPlayer,
    required this.onGoals,
    required this.onConfirm,
  });
  final MatchEditDraft draft;
  final int number;
  final List<Player> players;
  final ValueChanged<int> onScore;
  final VoidCallback onEditScore, onConfirm;
  final ValueChanged<int> onPlayer;
  final void Function(String id, int delta) onGoals;

  @override
  Widget build(BuildContext context) {
    final color = number == 1 ? AppColors.teamOne : AppColors.teamTwo;
    final foreground = number == 1 ? AppColors.onPrimary : AppColors.ink;
    final team = draft.team(number);
    final missing = draft.missing(number);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Material(
      key: ValueKey('edit-team-$number'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.all(AppSpace.medium),
            child: LayoutBuilder(
              builder: (context, box) {
                final heading = Text(
                  'SQUADRA $number',
                  style: AppType.section.copyWith(color: foreground),
                );
                final counter = EditCounter(
                  value: draft.score(number),
                  label: 'Punteggio squadra $number',
                  valueKey: ValueKey('edit-score-$number'),
                  color: color,
                  onDecrease: draft.score(number) > 0
                      ? () => onScore(draft.score(number) - 1)
                      : null,
                  onIncrease: () => onScore(draft.score(number) + 1),
                  onValue: onEditScore,
                );
                return box.maxWidth < 320 || scale > 1.3
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          heading,
                          const SizedBox(height: AppSpace.small),
                          counter,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: heading),
                          const SizedBox(width: 8),
                          SizedBox(width: 160, child: counter),
                        ],
                      );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.medium),
            child: Column(
              children: [
                for (var slot = 0; slot < draft.mode.teamSize; slot++) ...[
                  if (slot > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpace.small,
                    ),
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final id = slot < team.length ? team[slot] : '';
                        final name = id.isEmpty
                            ? 'Aggiungi giocatore'
                            : StatsService.playerName(players, id);
                        final archived = players.any(
                          (p) => p.id == id && p.isArchived,
                        );
                        final identity = Semantics(
                          button: true,
                          label:
                              'Cambia giocatore ${slot + 1}, squadra $number: $name',
                          child: InkWell(
                            key: ValueKey('edit-player-$number-$slot'),
                            onTap: () => onPlayer(slot),
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: AppSpace.touch,
                              ),
                              child: ExcludeSemantics(
                                child: Row(
                                  children: [
                                    if (id.isNotEmpty)
                                      PlayerAvatar(name: name, color: color),
                                    if (id.isEmpty)
                                      Icon(
                                        Icons.person_add_alt_1,
                                        color: color,
                                      ),
                                    const SizedBox(width: AppSpace.small),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: AppType.bodyStrong),
                                          if (archived)
                                            Text(
                                              'Archiviato',
                                              style: AppType.utility.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                        if (id.isEmpty) return identity;
                        final goals = EditCounter(
                          value: draft.goalsFor(id),
                          label: 'Gol di $name, squadra $number',
                          valueKey: ValueKey('edit-goals-$number-$id'),
                          color: color,
                          suffix: ' gol',
                          onDecrease: draft.goalsFor(id) > 0
                              ? () => onGoals(id, -1)
                              : null,
                          onIncrease: missing > 0 ? () => onGoals(id, 1) : null,
                        );
                        if (draft.mode == MatchMode.oneVsOne && missing >= 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              identity,
                              Padding(
                                padding: const EdgeInsets.only(left: 44),
                                child: Text(
                                  '${draft.goalsFor(id)} ${draft.goalsFor(id) == 1 ? 'gol assegnato' : 'gol assegnati'}',
                                  style: AppType.utility.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        if (box.maxWidth < 330 || scale > 1.3) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              identity,
                              const SizedBox(height: AppSpace.micro),
                              goals,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: identity),
                            const SizedBox(width: 8),
                            SizedBox(width: 160, child: goals),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (draft.mode == MatchMode.oneVsOne &&
              missing > 0 &&
              team.length == 1 &&
              team.single.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.medium),
              child: OutlinedButton(
                key: ValueKey('edit-confirm-scorer-$number'),
                onPressed: onConfirm,
                child: Text(
                  'Conferma $missing gol a ${StatsService.playerName(players, team.single)}',
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, box) {
              final decorate = scale <= 1.3 && box.maxWidth >= 330;
              return Stack(
                children: [
                  if (decorate)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      width: 100,
                      height: 44,
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: CustomPaint(painter: ProfileCornerSweep()),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      10,
                      decorate ? 104 : 12,
                      12,
                    ),
                    child: Text(
                      '${draft.assigned(number)} / ${draft.score(number)} gol assegnati'
                      '${missing < 0
                          ? ' · Rimuovi ${-missing}'
                          : missing > 0
                          ? ' · Mancano $missing'
                          : ''}',
                      key: ValueKey('edit-total-$number'),
                      style: AppType.utility.copyWith(
                        color: missing == 0
                            ? AppColors.textSecondary
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class EditCounter extends StatelessWidget {
  const EditCounter({
    super.key,
    required this.value,
    required this.label,
    required this.valueKey,
    required this.color,
    this.suffix = '',
    this.onDecrease,
    this.onIncrease,
    this.onValue,
  });
  final int value;
  final String label, suffix;
  final Key valueKey;
  final Color color;
  final VoidCallback? onDecrease, onIncrease, onValue;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(AppRadius.control),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Diminuisci $label',
          onPressed: onDecrease,
          color: color,
          icon: const Icon(Icons.remove),
        ),
        Expanded(
          child: Semantics(
            label: '$label: $value',
            button: onValue != null,
            onTap: onValue,
            child: ExcludeSemantics(
              child: InkWell(
                onTap: onValue,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSpace.touch),
                  child: Center(
                    child: Text(
                      '$value$suffix',
                      key: valueKey,
                      textAlign: TextAlign.center,
                      style: suffix.isEmpty
                          ? AppType.section.copyWith(fontSize: 30)
                          : AppType.bodyStrong,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Aumenta $label',
          onPressed: onIncrease,
          color: color,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );
}
