import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app_presentation.dart';

import '../../../cubits/players/players_cubit.dart';
import '../../../cubits/players/players_state.dart';
import '../../../models/player.dart';
import '../../../navigation/app_navigation.dart';
import '../theme/italia90_tokens.dart';
import '../widgets/italia90_components.dart';
import '../widgets/italia_graphic_backdrop.dart';
import 'players/player_dialogs.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayersCubit, PlayersState>(
      listenWhen: (previous, current) =>
          current.feedback != null && current.feedback != previous.feedback,
      listener: (context, state) {
        if (!AppPresentationScope.isActiveOf(context)) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(playersFeedbackText(state.feedback!))),
          );
      },
      builder: (context, state) {
        final activePlayers = state.active;
        final archivedPlayers = state.archived;
        final presentCount = state.present.length;

        return Scaffold(
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: ItaliaAction(
                label: 'NUOVO GIOCATORE',
                icon: Icons.person_add_alt_1,
                onPressed: state.isMutating
                    ? null
                    : () => showPlayerAddDialog(context),
              ),
            ),
          ),
          body: ItaliaGraphicBackdrop(
            variant: ItaliaBackdropVariant.working,
            child: SafeArea(
              bottom: false,
              child: ListView(
                key: const ValueKey('players-scroll'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  const ItaliaCompactMasthead(
                    semanticsKey: ValueKey('players-masthead'),
                    footballKey: ValueKey('players-brand-football'),
                  ),
                  const SizedBox(height: 18),
                  const _PlayersTitle(),
                  const SizedBox(height: 12),
                  _Summary(
                    presentCount: presentCount,
                    total: activePlayers.length,
                  ),
                  const SizedBox(height: 20),
                  if (activePlayers.isEmpty && archivedPlayers.isEmpty)
                    const _Empty()
                  else ...[
                    if (activePlayers.isNotEmpty)
                      _PlayerPanel(
                        key: const ValueKey('players-active-panel'),
                        players: activePlayers,
                        isMutating: state.isMutating,
                        onToggle: (player) =>
                            context.read<PlayersCubit>().togglePresent(player),
                        onRename: (player) =>
                            showPlayerRenameDialog(context, player),
                        onArchive: (player) =>
                            showPlayerArchiveDialog(context, player),
                        onReactivate: (player) => context
                            .read<PlayersCubit>()
                            .reactivatePlayer(player),
                        onOpenProfile: (player) =>
                            openPlayerProfile(context, player.id),
                      ),
                    if (archivedPlayers.isNotEmpty) ...[
                      if (activePlayers.isNotEmpty) const SizedBox(height: 24),
                      const _ArchivedHeading(),
                      const SizedBox(height: 8),
                      _PlayerPanel(
                        key: const ValueKey('players-archived-panel'),
                        players: archivedPlayers,
                        isMutating: state.isMutating,
                        onToggle: (player) =>
                            context.read<PlayersCubit>().togglePresent(player),
                        onRename: (player) =>
                            showPlayerRenameDialog(context, player),
                        onArchive: (player) =>
                            showPlayerArchiveDialog(context, player),
                        onReactivate: (player) => context
                            .read<PlayersCubit>()
                            .reactivatePlayer(player),
                        onOpenProfile: (player) =>
                            openPlayerProfile(context, player.id),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.presentCount, required this.total});
  final int presentCount;
  final int total;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        _SummaryChip(
          key: const ValueKey('players-summary-present'),
          labelKey: const ValueKey('players-summary-present-label'),
          maxWidth: constraints.maxWidth,
          label: '$presentCount/$total presenti',
          leadingText: '$presentCount/$total',
          trailingText: 'presenti',
          color: Italia90.teamOne,
        ),
        _SummaryChip(
          key: const ValueKey('players-summary-ready'),
          labelKey: const ValueKey('players-summary-ready-label'),
          maxWidth: constraints.maxWidth,
          label: presentCount >= 2
              ? 'Pronti a giocare'
              : 'Servono ${2 - presentCount} per giocare',
          color: presentCount >= 2 ? Italia90.success : Italia90.muted,
        ),
      ],
    ),
  );
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    super.key,
    required this.labelKey,
    required this.maxWidth,
    required this.label,
    this.leadingText,
    this.trailingText,
    required this.color,
  });

  final Key labelKey;
  final double maxWidth;
  final String label;
  final String? leadingText;
  final String? trailingText;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: Italia90.touch,
        maxWidth: maxWidth,
      ),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Italia90.surface,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: _SummaryLabel(
          key: labelKey,
          label: label,
          leadingText: leadingText,
          trailingText: trailingText,
          color: color,
        ),
      ),
    ),
  );
}

class _SummaryLabel extends StatelessWidget {
  const _SummaryLabel({
    super.key,
    required this.label,
    required this.leadingText,
    required this.trailingText,
    required this.color,
  });

  final String label;
  final String? leadingText;
  final String? trailingText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Italia90.body.copyWith(
      color: color,
      fontSize: 17,
      height: 1.15,
      fontWeight: FontWeight.w700,
    );
    final leading = leadingText;
    final trailing = trailingText;
    if (leading == null || trailing == null) {
      return Text(label, textAlign: TextAlign.center, style: style);
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Text(
              key: const ValueKey('players-summary-present-number'),
              leading,
              style: style,
            ),
          ),
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Transform.translate(
              // Optical correction aligns the word with the adjacent numeral.
              offset: const Offset(0, -1),
              child: Text(
                key: const ValueKey('players-summary-present-word'),
                trailing,
                style: style,
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

class _PlayersTitle extends StatelessWidget {
  const _PlayersTitle();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: 'GIOCATORI',
    child: Text(
      key: const ValueKey('players-title'),
      'GIOCATORI',
      textAlign: TextAlign.center,
      style: Italia90.heading.copyWith(fontSize: 32, height: 1.05),
    ),
  );
}

class _ArchivedHeading extends StatelessWidget {
  const _ArchivedHeading();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: 'ARCHIVIATI',
    child: Text('ARCHIVIATI', style: Italia90.heading.copyWith(fontSize: 24)),
  );
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    super.key,
    required this.players,
    required this.isMutating,
    required this.onToggle,
    required this.onRename,
    required this.onArchive,
    required this.onReactivate,
    required this.onOpenProfile,
  });

  final List<Player> players;
  final bool isMutating;
  final ValueChanged<Player> onToggle;
  final ValueChanged<Player> onRename;
  final ValueChanged<Player> onArchive;
  final ValueChanged<Player> onReactivate;
  final ValueChanged<Player> onOpenProfile;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Italia90.panel,
      border: Border.all(color: Italia90.subtle),
      borderRadius: BorderRadius.circular(Italia90.panelRadius),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(Italia90.panelRadius),
      child: Column(
        children: [
          for (var index = 0; index < players.length; index++) ...[
            _PlayerRow(
              key: ValueKey('player-${players[index].id}'),
              player: players[index],
              onToggle: isMutating || players[index].isArchived
                  ? null
                  : () => onToggle(players[index]),
              onRename: isMutating ? null : () => onRename(players[index]),
              onArchive: isMutating || players[index].isArchived
                  ? null
                  : () => onArchive(players[index]),
              onReactivate: isMutating || !players[index].isArchived
                  ? null
                  : () => onReactivate(players[index]),
              onOpenProfile: () => onOpenProfile(players[index]),
            ),
            if (index < players.length - 1)
              const Divider(indent: 76, endIndent: 16),
          ],
        ],
      ),
    ),
  );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    super.key,
    required this.player,
    required this.onToggle,
    required this.onRename,
    required this.onArchive,
    required this.onReactivate,
    required this.onOpenProfile,
  });

  final Player player;
  final VoidCallback? onToggle;
  final VoidCallback? onRename;
  final VoidCallback? onArchive;
  final VoidCallback? onReactivate;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        switchTheme: theme.switchTheme.copyWith(
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Italia90.success
                : Italia90.subtle,
          ),
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      child: ItaliaRosterRow(
        name: player.name,
        present: player.isPresent,
        archived: player.isArchived,
        avatarColor: Italia90.avatarNeutral,
        avatarSize: 56,
        presenceKey: ValueKey('player-presence-${player.id}'),
        onProfile: onOpenProfile,
        onPresence: onToggle == null ? null : (_) => onToggle!(),
        actions: PopupMenuButton<_PlayerAction>(
          key: ValueKey('player-actions-${player.id}'),
          tooltip: 'Azioni giocatore: ${player.name}',
          onSelected: (action) {
            switch (action) {
              case _PlayerAction.rename:
                onRename?.call();
              case _PlayerAction.profile:
                onOpenProfile();
              case _PlayerAction.archive:
                onArchive?.call();
              case _PlayerAction.reactivate:
                onReactivate?.call();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<_PlayerAction>(
              value: _PlayerAction.profile,
              child: ListTile(
                leading: Icon(Icons.person_search),
                title: Text('Profilo'),
              ),
            ),
            PopupMenuItem<_PlayerAction>(
              enabled: onRename != null,
              value: _PlayerAction.rename,
              child: const ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifica nome'),
              ),
            ),
            if (player.isArchived)
              PopupMenuItem<_PlayerAction>(
                enabled: onReactivate != null,
                value: _PlayerAction.reactivate,
                child: const ListTile(
                  leading: Icon(Icons.unarchive),
                  title: Text('Riattiva'),
                ),
              )
            else
              PopupMenuItem<_PlayerAction>(
                enabled: onArchive != null,
                value: _PlayerAction.archive,
                child: const ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Archivia'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _PlayerAction { profile, rename, archive, reactivate }

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Italia90.muted),
          SizedBox(height: 16),
          Text(
            'Nessun giocatore',
            style: TextStyle(
              color: Italia90.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Aggiungi il primo player con il pulsante in basso.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Italia90.muted),
          ),
        ],
      ),
    ),
  );
}
