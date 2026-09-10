import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/design/adaptive_pair.dart';

const _teamStageAsset =
    'design/south-africa-2010/assets/setup-r2/approved/'
    'team-stage-v10-gimp-white-to-alpha.png';

class MatchTeamStage extends StatelessWidget {
  const MatchTeamStage({
    super.key,
    required this.showArtwork,
    required this.players,
    required this.team1,
    required this.team2,
    required this.capacity,
    required this.enabled,
    required this.onAdd,
    required this.onEdit,
  });

  final bool showArtwork;
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
          if (showArtwork)
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
                      key: ValueKey('team-$team-player-$id'),
                      team: team,
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
                Semantics(
                  key: ValueKey('add-team-$team'),
                  button: true,
                  enabled: enabled && playerIds.length < capacity,
                  label: 'Aggiungi giocatore alla Squadra $team',
                  onTap: enabled && playerIds.length < capacity ? onAdd : null,
                  child: ExcludeSemantics(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Material(
                        color: AppColors.surface.withValues(alpha: .96),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: color.withValues(alpha: .35)),
                        ),
                        child: InkWell(
                          onTap: enabled && playerIds.length < capacity
                              ? onAdd
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  textAlign: TextAlign.center,
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

class _TeamPlayerSlot extends StatelessWidget {
  const _TeamPlayerSlot({
    super.key,
    required this.team,
    required this.name,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final int team;
  final String name;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: '$name, modifica Squadra $team',
    onTap: enabled ? onTap : null,
    child: ExcludeSemantics(
      child: Material(
        color: AppColors.surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
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
                      name,
                      maxLines: 2,
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
    constraints: const BoxConstraints(minHeight: 54),
    decoration: BoxDecoration(
      color: AppColors.teamContainer(color),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .2)),
    ),
  );
}

class _TeamStageArtwork extends StatelessWidget {
  const _TeamStageArtwork();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Image.asset(
        _teamStageAsset,
        key: const ValueKey('setup-team-artwork'),
        width: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      ),
    ),
  );
}
