import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/new_match/new_match_cubit.dart';
import '../../../../cubits/new_match/new_match_state.dart';
import '../../../../models/player.dart';
import '../../../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';

Future<void> showAllMatchPlayersSheet(
  BuildContext context,
  NewMatchCubit cubit,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => BlocProvider.value(
    value: cubit,
    child: BlocBuilder<NewMatchCubit, NewMatchState>(
      buildWhen: (previous, current) =>
          previous.players != current.players ||
          previous.assignment != current.assignment,
      builder: (_, state) => _RosterSheet(
        title: 'GIOCATORI DISPONIBILI',
        itemCount: state.present.length,
        itemBuilder: (_, index) {
          final player = state.present[index];
          return _RosterStatusRow(
            key: ValueKey('roster-sheet-player-${player.id}'),
            player: player,
            team: state.assignment[player.id],
          );
        },
      ),
    ),
  ),
);

Future<void> showMatchTeamPlayersSheet(
  BuildContext context,
  NewMatchCubit cubit,
  int team, {
  String? replacingId,
}) {
  final teamColor = team == 1 ? AppColors.teamOne : AppColors.teamTwo;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<NewMatchCubit, NewMatchState>(
        buildWhen: (previous, current) =>
            previous.players != current.players ||
            previous.assignment != current.assignment ||
            previous.mode != current.mode ||
            previous.kickedOff != current.kickedOff ||
            previous.isSaving != current.isSaving ||
            previous.isPersistingRules != current.isPersistingRules,
        builder: (sheetContext, state) {
          final effectiveReplacingId =
              replacingId != null && state.assignment[replacingId] == team
              ? replacingId
              : null;
          final teamHasCapacity = state.team(team).length < state.mode.teamSize;
          final canAssign =
              !state.kickedOff &&
              !state.isSaving &&
              !state.isPersistingRules &&
              (effectiveReplacingId != null || teamHasCapacity);
          final candidates = state.present
              .where((player) => !state.assignment.containsKey(player.id))
              .toList(growable: false);
          final showCandidates =
              teamHasCapacity || effectiveReplacingId != null;
          final leadingItemCount = effectiveReplacingId == null ? 0 : 1;
          final message = !teamHasCapacity && effectiveReplacingId == null
              ? 'La squadra è già completa.'
              : candidates.isEmpty
              ? effectiveReplacingId == null
                    ? 'Nessun altro giocatore disponibile.'
                    : 'Non ci sono giocatori disponibili per la sostituzione.'
              : null;
          final messageItemCount = message == null ? 0 : 1;
          final candidateCount = showCandidates ? candidates.length : 0;

          return _RosterSheet(
            title: effectiveReplacingId == null
                ? 'AGGIUNGI A SQUADRA $team'
                : 'MODIFICA SQUADRA $team',
            itemCount: leadingItemCount + messageItemCount + candidateCount,
            itemBuilder: (_, index) {
              if (effectiveReplacingId != null && index == 0) {
                return Card(
                  child: ListTile(
                    key: ValueKey('remove-$effectiveReplacingId-team-$team'),
                    leading: const Icon(
                      Icons.person_remove_outlined,
                      color: AppColors.error,
                    ),
                    title: Text(
                      'Rimuovi ${StatsService.playerName(state.players, effectiveReplacingId)}',
                    ),
                    onTap: !canAssign
                        ? null
                        : () {
                            cubit.setTeam(effectiveReplacingId, team);
                            Navigator.pop(sheetContext);
                          },
                  ),
                );
              }

              final contentIndex = index - leadingItemCount;
              if (message != null && contentIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppType.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              final player = candidates[contentIndex - messageItemCount];
              void assign() {
                if (effectiveReplacingId == null) {
                  cubit.setTeam(player.id, team);
                } else {
                  cubit.replaceTeamPlayer(
                    outgoingPlayerId: effectiveReplacingId,
                    incomingPlayerId: player.id,
                    team: team,
                  );
                }
                Navigator.pop(sheetContext);
              }

              return Semantics(
                key: ValueKey('team-chip-${player.id}-team-$team'),
                container: true,
                button: true,
                enabled: canAssign,
                selected: false,
                label: '${player.name}, Squadra $team',
                onTap: canAssign ? assign : null,
                child: ExcludeSemantics(
                  child: Card(
                    child: ListTile(
                      leading: PlayerAvatar(
                        name: player.name,
                        color: teamColor,
                      ),
                      title: Text(player.name, style: AppType.bodyStrong),
                      trailing: Icon(Icons.add_circle, color: teamColor),
                      onTap: canAssign ? assign : null,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

class MatchRosterSummary extends StatelessWidget {
  const MatchRosterSummary({
    super.key,
    required this.players,
    required this.totalCount,
    required this.assignment,
    required this.enoughPlayers,
    required this.neededMessage,
    required this.onShowAll,
  });

  final List<Player> players;
  final int totalCount;
  final Map<String, int> assignment;
  final bool enoughPlayers;
  final String neededMessage;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
            const title = Text('GIOCATORI DISPONIBILI', style: AppType.section);
            final action = onShowAll == null
                ? null
                : TextButton(
                    onPressed: onShowAll,
                    child: Text('VEDI TUTTI ($totalCount)'),
                  );
            if (stacked && action != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }
            return Row(
              children: [
                const Expanded(child: title),
                if (action != null) action,
              ],
            );
          },
        ),
      ),
      Container(
        decoration: BoxDecoration(
          // Keep the explanatory copy on a stable surface instead of letting
          // the poster artwork reduce its contrast behind the text.
          color: AppColors.surface.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(AppRadius.panel),
          border: Border.all(color: AppColors.outline.withValues(alpha: .28)),
        ),
        child: Column(
          children: [
            if (!enoughPlayers)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      neededMessage,
                      style: AppType.body.copyWith(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Vai su Giocatori e segna chi è presente.',
                      style: AppType.body.copyWith(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 4, 14, 16),
                child: Text('Nessun giocatore presente.', style: AppType.body),
              ),
            for (var index = 0; index < players.length; index++) ...[
              if (index > 0)
                const Divider(height: 1, indent: 54, endIndent: 12),
              _RosterStatusRow(
                key: ValueKey('present-player-${players[index].id}'),
                player: players[index],
                team: assignment[players[index].id],
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _RosterStatusRow extends StatelessWidget {
  const _RosterStatusRow({super.key, required this.player, required this.team});

  final Player player;
  final int? team;

  @override
  Widget build(BuildContext context) {
    final color = team == 1
        ? AppColors.teamOne
        : team == 2
        ? AppColors.teamTwo
        : AppColors.ink;
    return Semantics(
      excludeSemantics: true,
      label: team == null
          ? '${player.name}, non assegnato'
          : '${player.name}, Squadra $team',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            PlayerAvatar(name: player.name, size: 34, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.bodyStrong,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: team == null ? Colors.transparent : color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: team == null ? AppColors.outline : color,
                  width: 1.5,
                ),
              ),
              child: team == null
                  ? null
                  : const Icon(
                      Icons.check,
                      size: 19,
                      color: AppColors.onPrimary,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterSheet extends StatelessWidget {
  const _RosterSheet({
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: .62,
      minChildSize: .35,
      maxChildSize: .9,
      builder: (_, controller) => ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: itemCount + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 10),
              child: Text(title, style: AppType.section),
            );
          }
          return itemBuilder(context, index - 2);
        },
      ),
    ),
  );
}
