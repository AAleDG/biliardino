import 'package:flutter/material.dart';

import '../../models/game_match.dart';
import '../../models/match_rules.dart';
import '../../models/player.dart';
import '../../models/rivalry_overview.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../avatar.dart';
import 'adaptive_pair.dart';

const _teamStageAsset =
    'design/south-africa-2010/assets/setup-r2/candidates/'
    'team-stage-v10-gimp-white-to-alpha.png';
const _lowerFlourishAsset =
    'design/south-africa-2010/assets/setup-r2/candidates/'
    'lower-flourish-v5-transparent.png';

class MatchSetupView extends StatefulWidget {
  const MatchSetupView({
    super.key,
    required this.players,
    required this.matches,
    required this.mode,
    required this.rules,
    required this.isPersistingRules,
    required this.isRivalry,
    required this.present,
    required this.team1,
    required this.team2,
    required this.assignment,
    required this.onModeChanged,
    required this.onRuleModeChanged,
    required this.onTargetScoreChanged,
    required this.onWinByTwoChanged,
    required this.onRivalryChanged,
    required this.onRandomTeams,
    required this.onBalancedTeams,
    required this.onToggle,
    required this.onReplace,
    required this.onKickoff,
  });

  final List<Player> players;
  final List<GameMatch> matches;
  final MatchMode mode;
  final MatchRules rules;
  final bool isPersistingRules;
  final bool isRivalry;
  final List<Player> present;
  final List<String> team1;
  final List<String> team2;
  final Map<String, int> assignment;
  final ValueChanged<MatchMode> onModeChanged;
  final ValueChanged<MatchRuleMode> onRuleModeChanged;
  final ValueChanged<int> onTargetScoreChanged;
  final ValueChanged<bool> onWinByTwoChanged;
  final ValueChanged<bool> onRivalryChanged;
  final VoidCallback onRandomTeams;
  final VoidCallback onBalancedTeams;
  final void Function(String id, int team) onToggle;
  final void Function({
    required String outgoingPlayerId,
    required String incomingPlayerId,
    required int team,
  })
  onReplace;
  final VoidCallback? onKickoff;

  @override
  State<MatchSetupView> createState() => _MatchSetupViewState();
}

class _MatchSetupViewState extends State<MatchSetupView> {
  bool _optionsExpanded = false;

  String _playerName(String id) => StatsService.playerName(widget.players, id);

  Future<void> _showAllPlayers() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _RosterSheet(
      title: 'GIOCATORI DISPONIBILI',
      children: [
        for (final player in widget.present)
          _RosterStatusRow(
            key: ValueKey('roster-sheet-player-${player.id}'),
            player: player,
            team: widget.assignment[player.id],
          ),
      ],
    ),
  );

  Future<void> _showTeamPlayers(int team, {String? replacingId}) {
    final candidates = widget.present
        .where((player) => !widget.assignment.containsKey(player.id))
        .toList(growable: false);
    final teamColor = team == 1 ? AppColors.teamOne : AppColors.teamTwo;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => _RosterSheet(
        title: replacingId == null
            ? 'AGGIUNGI A SQUADRA $team'
            : 'MODIFICA SQUADRA $team',
        children: [
          if (replacingId != null)
            Card(
              child: ListTile(
                key: ValueKey('remove-$replacingId-team-$team'),
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.error,
                ),
                title: Text('Rimuovi ${_playerName(replacingId)}'),
                onTap: widget.isPersistingRules
                    ? null
                    : () {
                        widget.onToggle(replacingId, team);
                        Navigator.pop(sheetContext);
                      },
              ),
            ),
          if (candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                replacingId == null
                    ? 'Nessun altro giocatore disponibile.'
                    : 'Non ci sono giocatori disponibili per la sostituzione.',
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
          for (final player in candidates)
            Semantics(
              key: ValueKey('team-chip-${player.id}-team-$team'),
              container: true,
              button: true,
              enabled: !widget.isPersistingRules,
              selected: false,
              label: '${player.name}, Squadra $team',
              onTap: widget.isPersistingRules
                  ? null
                  : () => _assignFromSheet(
                      sheetContext,
                      player.id,
                      team,
                      replacingId: replacingId,
                    ),
              child: ExcludeSemantics(
                child: Card(
                  child: ListTile(
                    leading: PlayerAvatar(name: player.name, color: teamColor),
                    title: Text(player.name, style: AppType.bodyStrong),
                    trailing: Icon(Icons.add_circle, color: teamColor),
                    onTap: widget.isPersistingRules
                        ? null
                        : () => _assignFromSheet(
                            sheetContext,
                            player.id,
                            team,
                            replacingId: replacingId,
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _assignFromSheet(
    BuildContext sheetContext,
    String incomingId,
    int team, {
    String? replacingId,
  }) {
    if (replacingId == null) {
      widget.onToggle(incomingId, team);
    } else {
      widget.onReplace(
        outgoingPlayerId: replacingId,
        incomingPlayerId: incomingId,
        team: team,
      );
    }
    Navigator.pop(sheetContext);
  }

  @override
  Widget build(BuildContext context) {
    final requiredPlayers = widget.mode.teamSize * 2;
    final enoughPlayers = widget.present.length >= requiredPlayers;
    final teamsReady =
        widget.team1.length == widget.mode.teamSize &&
        widget.team2.length == widget.mode.teamSize;
    final rivalry = widget.isRivalry && teamsReady
        ? StatsService.rivalryOverview(
            widget.matches,
            team1Ids: widget.team1,
            team2Ids: widget.team2,
          )
        : null;

    return Stack(
      children: [
        if (MediaQuery.textScalerOf(context).scale(1) <= 1.35)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: IgnorePointer(child: _LowerFlourish()),
          ),
        SafeArea(
          bottom: false,
          child: ListView(
            key: const ValueKey('setup-scroll-view'),
            padding: const EdgeInsets.only(bottom: 116),
            children: [
              const _SetupHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _ModeSelector(
                  selectedMode: widget.mode,
                  onChanged: widget.isPersistingRules
                      ? null
                      : widget.onModeChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _OptionsDisclosure(
                  expanded: _optionsExpanded,
                  onExpansionChanged: (value) =>
                      setState(() => _optionsExpanded = value),
                  rules: widget.rules,
                  mode: widget.mode,
                  isPersistingRules: widget.isPersistingRules,
                  isRivalry: widget.isRivalry,
                  teamsReady: teamsReady,
                  rivalry: rivalry,
                  team1Label: _teamLabel(widget.team1, 'Squadra 1'),
                  team2Label: _teamLabel(widget.team2, 'Squadra 2'),
                  onRuleModeChanged: widget.onRuleModeChanged,
                  onTargetScoreChanged: widget.onTargetScoreChanged,
                  onWinByTwoChanged: widget.onWinByTwoChanged,
                  onRandomTeams: widget.onRandomTeams,
                  onBalancedTeams: widget.onBalancedTeams,
                  onRivalryChanged: widget.onRivalryChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: _RosterSummary(
                  players: widget.present.take(4).toList(growable: false),
                  totalCount: widget.present.length,
                  assignment: widget.assignment,
                  enoughPlayers: enoughPlayers,
                  neededMessage:
                      'Servono almeno $requiredPlayers giocatori presenti per '
                      'una partita ${_modeTitle(widget.mode)}.',
                  onShowAll: widget.present.length > 4 ? _showAllPlayers : null,
                ),
              ),
              const SizedBox(height: 6),
              _TeamStage(
                players: widget.players,
                team1: widget.team1,
                team2: widget.team2,
                capacity: widget.mode.teamSize,
                enabled: enoughPlayers && !widget.isPersistingRules,
                onAdd: (team) => _showTeamPlayers(team),
                onEdit: (team, playerId) =>
                    _showTeamPlayers(team, replacingId: playerId),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: _KickoffButton(onPressed: widget.onKickoff),
        ),
      ],
    );
  }

  String _teamLabel(List<String> ids, String fallback) =>
      ids.isEmpty ? fallback : ids.map(_playerName).join(' / ');
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
    child: Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            'NUOVA PARTITA',
            textAlign: TextAlign.center,
            style: AppType.screen.copyWith(fontSize: 36),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'SCEGLI I GIOCATORI E FORMA LE SQUADRE',
          textAlign: TextAlign.center,
          style: AppType.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: .7,
          ),
        ),
      ],
    ),
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selectedMode, required this.onChanged});

  final MatchMode selectedMode;
  final ValueChanged<MatchMode>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: (MediaQuery.textScalerOf(context).scale(28) * 1.1 + 8).clamp(
      58.0,
      double.infinity,
    ),
    padding: const EdgeInsets.all(1),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        for (final mode in MatchMode.values)
          Expanded(
            child: _ModeChoice(
              mode: mode,
              selected: mode == selectedMode,
              onTap: onChanged == null ? null : () => onChanged!(mode),
            ),
          ),
      ],
    ),
  );
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final MatchMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = _modeTitle(mode);
    final description = mode == MatchMode.oneVsOne
        ? '2 giocatori totali, uno per squadra.'
        : '4 giocatori totali, due per squadra.';
    final color = selected ? AppColors.onPrimary : AppColors.ink;
    return Semantics(
      key: ValueKey(
        'match-mode-${mode == MatchMode.oneVsOne ? 'one-vs-one' : 'two-vs-two'}',
      ),
      container: true,
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: '$title: $description',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(mode == MatchMode.oneVsOne ? 28 : 16),
            right: Radius.circular(mode == MatchMode.oneVsOne ? 16 : 28),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(mode == MatchMode.oneVsOne ? 28 : 16),
              right: Radius.circular(mode == MatchMode.oneVsOne ? 16 : 28),
            ),
            child: Center(
              child: Text(
                title,
                style: AppType.action.copyWith(color: color, fontSize: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RosterSummary extends StatelessWidget {
  const _RosterSummary({
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
          color: AppColors.surface.withValues(alpha: .32),
          borderRadius: BorderRadius.circular(AppRadius.panel),
          border: Border.all(color: AppColors.divider),
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
                      style: AppType.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Vai su Giocatori e segna chi è presente.',
                      style: AppType.caption.copyWith(
                        color: AppColors.textSecondary,
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
                maxLines: 1,
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

class _TeamStage extends StatelessWidget {
  const _TeamStage({
    required this.players,
    required this.team1,
    required this.team2,
    required this.capacity,
    required this.enabled,
    required this.onAdd,
    required this.onEdit,
  });

  final List<Player> players;
  final List<String> team1;
  final List<String> team2;
  final int capacity;
  final bool enabled;
  final ValueChanged<int> onAdd;
  final void Function(int team, String playerId) onEdit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.35;
      if (stacked) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 34),
          child: AdaptivePair(
            first: _TeamCard(
              team: 1,
              players: players,
              playerIds: team1,
              capacity: capacity,
              enabled: enabled,
              onAdd: () => onAdd(1),
              onEdit: (id) => onEdit(1, id),
            ),
            second: _TeamCard(
              team: 2,
              players: players,
              playerIds: team2,
              capacity: capacity,
              enabled: enabled,
              onAdd: () => onAdd(2),
              onEdit: (id) => onEdit(2, id),
            ),
          ),
        );
      }
      return Stack(
        key: const ValueKey('setup-team-stage'),
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: ClipRect(child: _TeamStageArtwork())),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _TeamCard(
                    team: 1,
                    players: players,
                    playerIds: team1,
                    capacity: capacity,
                    enabled: enabled,
                    onAdd: () => onAdd(1),
                    onEdit: (id) => onEdit(1, id),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Center(
                    child: ColoredBox(
                      color: AppColors.background,
                      child: Text(
                        'VS',
                        style: AppType.section.copyWith(fontSize: 32),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _TeamCard(
                    team: 2,
                    players: players,
                    playerIds: team2,
                    capacity: capacity,
                    enabled: enabled,
                    onAdd: () => onAdd(2),
                    onEdit: (id) => onEdit(2, id),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.players,
    required this.playerIds,
    required this.capacity,
    required this.enabled,
    required this.onAdd,
    required this.onEdit,
  });

  final int team;
  final List<Player> players;
  final List<String> playerIds;
  final int capacity;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    final color = team == 1 ? AppColors.teamOne : AppColors.teamTwo;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(34),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'SQUADRA $team',
                textAlign: TextAlign.center,
                style: AppType.section.copyWith(
                  color: AppColors.onTeam(color),
                  fontSize: 24,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final id in playerIds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: _TeamPlayerSlot(
                        name: StatsService.playerName(players, id),
                        color: color,
                        enabled: enabled,
                        onTap: () => onEdit(id),
                      ),
                    ),
                  for (var index = playerIds.length; index < capacity; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: _EmptyTeamSlot(color: color),
                    ),
                  SizedBox(
                    height: 64,
                    child: Material(
                      color: AppColors.surface.withValues(alpha: .96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: color.withValues(alpha: .35)),
                      ),
                      child: InkWell(
                        key: ValueKey('add-team-$team'),
                        onTap: enabled && playerIds.length < capacity
                            ? onAdd
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '+1',
                              style: AppType.section.copyWith(
                                color: color,
                                fontSize: 28,
                              ),
                            ),
                            Text(
                              'AGGIUNGI',
                              style: AppType.navigation.copyWith(
                                color: team == 1
                                    ? AppColors.primary
                                    : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamPlayerSlot extends StatelessWidget {
  const _TeamPlayerSlot({
    required this.name,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface.withValues(alpha: .96),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.teamContainer(color),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: color, size: 24),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.utility.copyWith(
                  color: AppColors.ink,
                  fontFamily: AppType.displayFamily,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyTeamSlot extends StatelessWidget {
  const _EmptyTeamSlot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    decoration: BoxDecoration(
      color: AppColors.teamContainer(color),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .2)),
    ),
  );
}

class _OptionsDisclosure extends StatelessWidget {
  const _OptionsDisclosure({
    required this.expanded,
    required this.onExpansionChanged,
    required this.rules,
    required this.mode,
    required this.isPersistingRules,
    required this.isRivalry,
    required this.teamsReady,
    required this.rivalry,
    required this.team1Label,
    required this.team2Label,
    required this.onRuleModeChanged,
    required this.onTargetScoreChanged,
    required this.onWinByTwoChanged,
    required this.onRandomTeams,
    required this.onBalancedTeams,
    required this.onRivalryChanged,
  });

  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final MatchRules rules;
  final MatchMode mode;
  final bool isPersistingRules;
  final bool isRivalry;
  final bool teamsReady;
  final RivalryOverview? rivalry;
  final String team1Label;
  final String team2Label;
  final ValueChanged<MatchRuleMode> onRuleModeChanged;
  final ValueChanged<int> onTargetScoreChanged;
  final ValueChanged<bool> onWinByTwoChanged;
  final VoidCallback onRandomTeams;
  final VoidCallback onBalancedTeams;
  final ValueChanged<bool> onRivalryChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface.withValues(alpha: .32),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.panel),
      side: const BorderSide(color: AppColors.divider),
    ),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: const ValueKey('setup-options-disclosure'),
      initiallyExpanded: expanded,
      onExpansionChanged: onExpansionChanged,
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      minTileHeight: 48,
      title: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('OPZIONI PARTITA', style: AppType.utility),
          Text(
            rules.mode == MatchRuleMode.free
                ? 'Punteggio libero'
                : 'Primo a ${rules.targetScore}${rules.winByTwo ? ' · +2' : ''}',
            style: AppType.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      children: [
        _RulesControls(
          rules: rules,
          disabled: isPersistingRules,
          onModeChanged: onRuleModeChanged,
          onTargetScoreChanged: onTargetScoreChanged,
          onWinByTwoChanged: onWinByTwoChanged,
        ),
        const SizedBox(height: 10),
        AdaptivePair(
          first: OutlinedButton.icon(
            key: const ValueKey('random-teams-action'),
            onPressed: isPersistingRules ? null : onRandomTeams,
            icon: const Icon(Icons.shuffle, size: 18),
            label: const Text('CASUALI'),
          ),
          second: OutlinedButton.icon(
            key: const ValueKey('balanced-teams-action'),
            onPressed: isPersistingRules ? null : onBalancedTeams,
            icon: const Icon(Icons.balance, size: 18),
            label: const Text('BILANCIATE'),
          ),
        ),
        if (teamsReady) ...[
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: isRivalry,
            onChanged: isPersistingRules
                ? null
                : (value) async {
                    if (!value) {
                      onRivalryChanged(false);
                      return;
                    }
                    final confirmed = await _confirmRivalry(context, mode);
                    if (confirmed) onRivalryChanged(true);
                  },
            contentPadding: EdgeInsets.zero,
            title: const Text('Modalità Rivalità'),
          ),
        ],
        if (isRivalry && rivalry != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              rivalry!.hasMatches
                  ? '$team1Label vs $team2Label · '
                        '${rivalry!.team1Wins}-${rivalry!.team2Wins} nei duelli'
                  : 'Primo duello tra $team1Label e $team2Label.',
              style: AppType.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    ),
  );
}

class _RulesControls extends StatelessWidget {
  const _RulesControls({
    required this.rules,
    required this.disabled,
    required this.onModeChanged,
    required this.onTargetScoreChanged,
    required this.onWinByTwoChanged,
  });

  final MatchRules rules;
  final bool disabled;
  final ValueChanged<MatchRuleMode> onModeChanged;
  final ValueChanged<int> onTargetScoreChanged;
  final ValueChanged<bool> onWinByTwoChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SegmentedButton<MatchRuleMode>(
        segments: const [
          ButtonSegment(value: MatchRuleMode.free, label: Text('Libero')),
          ButtonSegment(value: MatchRuleMode.firstTo, label: Text('Primo a N')),
        ],
        selected: {rules.mode},
        onSelectionChanged: disabled
            ? null
            : (selection) => onModeChanged(selection.single),
      ),
      if (rules.mode == MatchRuleMode.firstTo) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Text('Goal vittoria')),
            IconButton(
              onPressed:
                  disabled || rules.targetScore <= MatchRules.minTargetScore
                  ? null
                  : () => onTargetScoreChanged(rules.targetScore - 1),
              icon: const Icon(Icons.remove),
            ),
            Text('${rules.targetScore}', style: AppType.section),
            IconButton(
              onPressed:
                  disabled || rules.targetScore >= MatchRules.maxTargetScore
                  ? null
                  : () => onTargetScoreChanged(rules.targetScore + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        SwitchListTile.adaptive(
          value: rules.winByTwo,
          onChanged: disabled ? null : onWinByTwoChanged,
          contentPadding: EdgeInsets.zero,
          title: const Text('Vinci con due goal di scarto'),
        ),
      ],
    ],
  );
}

class _RosterSheet extends StatelessWidget {
  const _RosterSheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .62,
    minChildSize: .35,
    maxChildSize: .9,
    builder: (_, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(title, style: AppType.section),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

class _TeamStageArtwork extends StatelessWidget {
  const _TeamStageArtwork();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      _teamStageAsset,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
    ),
  );
}

class _LowerFlourish extends StatelessWidget {
  const _LowerFlourish();

  @override
  Widget build(BuildContext context) => ClipRect(
    child: OverflowBox(
      alignment: Alignment.bottomCenter,
      minWidth: 0,
      maxWidth: double.infinity,
      minHeight: 0,
      maxHeight: double.infinity,
      child: Transform.translate(
        // The approved PNG ends at alpha row 993, leaving 93 empty rows.
        offset: Offset(0, MediaQuery.sizeOf(context).width * 93 / 1448),
        child: ExcludeSemantics(
          child: Image.asset(
            _lowerFlourishAsset,
            width: MediaQuery.sizeOf(context).width,
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    ),
  );
}

class _KickoffButton extends StatelessWidget {
  const _KickoffButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(34),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 60,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.3),
          ),
          child: ElevatedButton.icon(
            key: const ValueKey('setup-kickoff-action'),
            onPressed: onPressed,
            icon: const Icon(Icons.play_arrow_rounded, size: 34),
            label: const Text('INIZIA PARTITA'),
            style:
                AppTheme.primaryButton(
                  background: AppColors.success,
                  foreground: AppColors.onPrimary,
                  pressed: AppColors.successPressed,
                ).copyWith(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  textStyle: WidgetStatePropertyAll(
                    AppType.action.copyWith(fontSize: 28),
                  ),
                ),
          ),
        ),
      ),
    ),
  );
}

Future<bool> _confirmRivalry(BuildContext context, MatchMode mode) async {
  final subject = mode == MatchMode.oneVsOne
      ? 'tra questi due giocatori'
      : 'tra queste due coppie';
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Attivare Rivalità?'),
          content: Text(
            'Puoi marcare questa partita come Rivalità $subject. Lo storico '
            'terrà separati i precedenti dedicati a questa sfida.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Attiva'),
            ),
          ],
        ),
      ) ??
      false;
}

String _modeTitle(MatchMode mode) =>
    mode == MatchMode.oneVsOne ? '1 VS 1' : '2 VS 2';
