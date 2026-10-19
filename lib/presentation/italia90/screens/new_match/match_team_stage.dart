import 'package:flutter/material.dart';

import '../../../../models/player.dart';
import '../../../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/italia90_tokens.dart';
import '../../widgets/design/adaptive_pair.dart';

/// Presents the two match teams as an assignment surface rather than a score
/// board. The surface owns only composition affordances; assignment rules stay
/// in [NewMatchCubit] and are expressed through the callbacks below.
class MatchTeamStage extends StatelessWidget {
  const MatchTeamStage({
    super.key,
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
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('setup-team-stage'),
    container: true,
    label: 'Assegnazione squadre',
    child: Padding(
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
    ),
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
    final teamColor = team == 1 ? Italia90.teamOne : Italia90.teamTwo;
    final onTeamColor = team == 1 ? Colors.white : Italia90.ink;
    final statusColor = team == 2 ? Italia90.ink : teamColor;
    final hasCapacity = playerIds.length < capacity;
    final complete = playerIds.length >= capacity;
    final panelColor = Italia90.surface.withValues(alpha: .9);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        border: Border.all(color: teamColor.withValues(alpha: .62)),
        borderRadius: BorderRadius.circular(Italia90.panelRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Italia90.panelRadius - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TeamHeader(
              team: team,
              count: playerIds.length,
              capacity: capacity,
              color: teamColor,
              onColor: onTeamColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < playerIds.length; index++)
                    _TeamPlayerSlot(
                      key: ValueKey('team-$team-player-${playerIds[index]}'),
                      team: team,
                      name: StatsService.playerName(players, playerIds[index]),
                      color: teamColor,
                      enabled: enabled,
                      isLast: index == playerIds.length - 1 && !hasCapacity,
                      onTap: () => onEdit(playerIds[index]),
                    ),
                  for (var index = playerIds.length; index < capacity; index++)
                    _EmptyTeamSlot(
                      key: ValueKey('team-$team-empty-$index'),
                      team: team,
                      color: teamColor,
                      enabled: enabled,
                      isLast: false,
                    ),
                  if (hasCapacity) ...[
                    const SizedBox(height: 8),
                    _AddPlayerButton(
                      key: ValueKey('add-team-$team'),
                      team: team,
                      color: teamColor,
                      enabled: enabled,
                      onPressed: onAdd,
                    ),
                  ] else
                    _TeamStatus(
                      key: ValueKey('team-$team-complete'),
                      icon: Icons.check_circle_outline,
                      label: 'SQUADRA COMPLETA',
                      color: statusColor,
                    ),
                  if (!enabled && hasCapacity) ...[
                    const SizedBox(height: 8),
                    const _TeamStatus(
                      icon: Icons.lock_outline,
                      label: 'ASSEGNAZIONE DISABILITATA',
                      color: Italia90.muted,
                    ),
                  ],
                  if (complete && !enabled)
                    const _TeamStatus(
                      icon: Icons.lock_outline,
                      label: 'MODIFICA DISABILITATA',
                      color: Italia90.muted,
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

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.team,
    required this.count,
    required this.capacity,
    required this.color,
    required this.onColor,
  });

  final int team;
  final int count;
  final int capacity;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'SQUADRA $team',
              style: Italia90.heading.copyWith(
                color: onColor,
                fontSize: 20,
                height: 1,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: onColor.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Text(
                '$count/$capacity',
                style: AppType.utility.copyWith(
                  color: color,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TeamPlayerSlot extends StatelessWidget {
  const _TeamPlayerSlot({
    super.key,
    required this.team,
    required this.name,
    required this.color,
    required this.enabled,
    required this.isLast,
    required this.onTap,
  });

  final int team;
  final String name;
  final Color color;
  final bool enabled;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: '$name, modifica Squadra $team',
    onTap: enabled ? onTap : null,
    child: ExcludeSemantics(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(bottom: BorderSide(color: Italia90.subtle)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                _TeamAvatar(color: color, enabled: enabled),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: Italia90.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: enabled ? Italia90.ink : Italia90.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: enabled ? color : Italia90.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _EmptyTeamSlot extends StatelessWidget {
  const _EmptyTeamSlot({
    super.key,
    required this.team,
    required this.color,
    required this.enabled,
    required this.isLast,
  });

  final int team;
  final Color color;
  final bool enabled;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final label = enabled ? 'POSTO DISPONIBILE' : 'IN ATTESA DI GIOCATORI';
    final icon = enabled
        ? Icons.person_outline_rounded
        : Icons.lock_outline_rounded;
    final foreground = enabled
        ? team == 2
              ? Italia90.ink
              : color
        : Italia90.muted;
    return Semantics(
      container: true,
      label: '$label per Squadra $team',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: .08)
                : Italia90.subtle.withValues(alpha: .72),
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: Italia90.subtle)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppType.utility.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPlayerButton extends StatelessWidget {
  const _AddPlayerButton({
    super.key,
    required this.team,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final int team;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    enabled: enabled,
    label: 'Aggiungi giocatore alla Squadra $team',
    onTap: enabled ? onPressed : null,
    child: ExcludeSemantics(
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('AGGIUNGI GIOCATORE'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          foregroundColor: color,
          disabledForegroundColor: Italia90.muted,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Italia90.subtle.withValues(alpha: .55),
          side: BorderSide(color: color.withValues(alpha: .72)),
          textStyle: AppType.utility,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Italia90.controlRadius),
          ),
        ),
      ),
    ),
  );
}

class _TeamStatus extends StatelessWidget {
  const _TeamStatus({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppType.utility.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.color, required this.enabled});

  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: enabled ? color.withValues(alpha: .14) : Italia90.subtle,
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.person,
      size: 22,
      color: enabled ? color : Italia90.muted,
    ),
  );
}
