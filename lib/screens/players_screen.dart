import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/players/players_cubit.dart';
import '../cubits/players/players_state.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import 'player_profile_screen.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayersCubit, PlayersState>(
      listenWhen: (previous, current) =>
          current.feedback != null && current.feedback != previous.feedback,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(_feedbackText(state.feedback!))),
          );
      },
      builder: (context, state) {
        final players = [...state.active, ...state.archived];
        final presentCount = state.present.length;

        return Scaffold(
          appBar: AppBar(title: const Text('GIOCATORI')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isMutating ? null : () => _showAddDialog(context),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('NUOVO'),
          ),
          body: players.isEmpty
              ? const _Empty()
              : Column(
                  children: [
                    _Summary(
                      presentCount: presentCount,
                      total: state.active.length,
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                        itemCount: players.length,
                        itemBuilder: (_, i) => _PlayerRow(
                          player: players[i],
                          onToggle: state.isMutating || players[i].isArchived
                              ? null
                              : () async {
                                  await context
                                      .read<PlayersCubit>()
                                      .togglePresent(players[i]);
                                },
                          onRename: state.isMutating
                              ? null
                              : () => _showRenameDialog(context, players[i]),
                          onArchive: state.isMutating || players[i].isArchived
                              ? null
                              : () => _showArchiveDialog(context, players[i]),
                          onReactivate:
                              state.isMutating || !players[i].isArchived
                              ? null
                              : () => context
                                    .read<PlayersCubit>()
                                    .reactivatePlayer(players[i]),
                          onOpenProfile: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PlayerProfileScreen(playerId: players[i].id),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

String _feedbackText(PlayersFeedback feedback) {
  switch (feedback) {
    case PlayersFeedback.addFailed:
      return 'Impossibile aggiungere il giocatore. Riprova.';
    case PlayersFeedback.renameFailed:
      return 'Impossibile rinominare il giocatore. Controlla il nome.';
    case PlayersFeedback.presenceUpdateFailed:
      return 'Impossibile aggiornare la presenza. Riprova.';
    case PlayersFeedback.archiveFailed:
      return 'Impossibile archiviare il giocatore. Riprova.';
    case PlayersFeedback.reactivateFailed:
      return 'Impossibile riattivare il giocatore. Riprova.';
  }
}

void _showArchiveDialog(BuildContext rootContext, Player player) {
  final cubit = rootContext.read<PlayersCubit>();
  showDialog<void>(
    context: rootContext,
    builder: (ctx) => AlertDialog(
      title: const Text('Archivia giocatore'),
      content: Text(
        'Archiviare ${player.name}? Rimarrà visibile nelle partite e nelle statistiche passate.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          key: const ValueKey('confirm-archive-player'),
          onPressed: () async {
            final archived = await cubit.archivePlayer(player);
            if (archived && ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Archivia'),
        ),
      ],
    ),
  );
}

void _showAddDialog(BuildContext rootContext) {
  final cubit = rootContext.read<PlayersCubit>();
  final controller = TextEditingController();
  Future<void> submit(BuildContext ctx) async {
    final name = controller.text.trim();
    if (name.isNotEmpty) {
      final added = await cubit.addPlayer(name);
      if (added && ctx.mounted) {
        Navigator.pop(ctx);
      }
    }
  }

  showDialog<void>(
    context: rootContext,
    builder: (ctx) => AlertDialog(
      title: const Text('Nuovo giocatore'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nome'),
        onSubmitted: (_) => submit(ctx),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () => submit(ctx),
          child: const Text('Aggiungi'),
        ),
      ],
    ),
  );
}

void _showRenameDialog(BuildContext rootContext, Player player) {
  final cubit = rootContext.read<PlayersCubit>();
  final controller = TextEditingController(text: player.name);
  Future<void> submit(BuildContext ctx) async {
    final renamed = await cubit.renamePlayer(player, controller.text);
    if (renamed && ctx.mounted) {
      Navigator.pop(ctx);
    }
  }

  showDialog<void>(
    context: rootContext,
    builder: (ctx) => AlertDialog(
      title: const Text('Modifica nome'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nome'),
        onSubmitted: (_) => submit(ctx),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () => submit(ctx),
          child: const Text('Salva'),
        ),
      ],
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.presentCount, required this.total});

  final int presentCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    const minimumPlayers = 2;
    final ready = presentCount >= minimumPlayers;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Pill(
            text: '$presentCount/$total presenti',
            color: NttColors.accentSoft,
          ),
          _Pill(
            text: ready
                ? 'Pronti a giocare'
                : 'Servono ${minimumPlayers - presentCount} per giocare',
            color: ready ? NttColors.success : NttColors.warning,
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
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
    return Card(
      child: InkWell(
        onTap: onOpenProfile,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              PlayerAvatar(name: player.name, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: shouldReduceMotion()
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _PresenceBadge(
                        key: ValueKey(
                          '${player.isPresent}-${player.isArchived}',
                        ),
                        isPresent: player.isPresent,
                        isArchived: player.isArchived,
                      ),
                    ),
                  ],
                ),
              ),
              if (!player.isArchived)
                Semantics(
                  key: ValueKey('player-presence-${player.id}'),
                  container: true,
                  label: 'Presenza di ${player.name}',
                  toggled: player.isPresent,
                  enabled: onToggle != null,
                  onTap: onToggle,
                  child: ExcludeSemantics(
                    child: Switch(
                      value: player.isPresent,
                      onChanged: onToggle == null ? null : (_) => onToggle!(),
                    ),
                  ),
                ),
              PopupMenuButton<_PlayerAction>(
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
            ],
          ),
        ),
      ),
    );
  }
}

enum _PlayerAction { profile, rename, archive, reactivate }

class _PresenceBadge extends StatelessWidget {
  const _PresenceBadge({
    super.key,
    required this.isPresent,
    required this.isArchived,
  });

  final bool isPresent;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    final color = isPresent && !isArchived
        ? NttColors.success
        : NttColors.textFaint;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isPresent && !isArchived
                ? [BoxShadow(color: color, blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            isArchived
                ? 'Archiviato'
                : isPresent
                ? 'In ufficio'
                : 'Assente',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: NttColors.textFaint),
          SizedBox(height: 16),
          Text(
            'Nessun giocatore',
            style: TextStyle(
              color: NttColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Aggiungi il primo player con il pulsante in basso.',
            textAlign: TextAlign.center,
            style: TextStyle(color: NttColors.textMuted),
          ),
        ],
      ),
    ),
  );
}
