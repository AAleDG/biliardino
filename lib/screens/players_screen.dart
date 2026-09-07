import 'package:flutter/material.dart';
import '../widgets/design/brand_header.dart';
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
          appBar: brandAppBar(context, title: 'GIOCATORI'),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isMutating ? null : () => _showAddDialog(context),
            backgroundColor: state.isMutating
                ? AppColors.disabledContainer
                : AppColors.primary,
            foregroundColor: state.isMutating
                ? AppColors.disabledContent
                : AppColors.onPrimary,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('NUOVO'),
          ),
          body: RibbonBackdrop(
            child: players.isEmpty
                ? const _Empty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: players.length + 1,
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return _Summary(
                          presentCount: presentCount,
                          total: state.active.length,
                        );
                      }
                      final i = index - 1;
                      return _PlayerRow(
                        first: i == 0,
                        last: i == players.length - 1,
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
                        onReactivate: state.isMutating || !players[i].isArchived
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
                      );
                    },
                  ),
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
    builder: (ctx) => BlocBuilder<PlayersCubit, PlayersState>(
      bloc: cubit,
      builder: (context, state) => PopScope(
        canPop: !state.isMutating,
        child: AlertDialog(
          scrollable: true,
          title: const Text('Archivia giocatore'),
          content: Text(
            'Archiviare ${player.name}? Rimarrà visibile nelle partite e nelle statistiche passate.',
          ),
          actions: [
            TextButton(
              onPressed: state.isMutating ? null : () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            ElevatedButton.icon(
              key: const ValueKey('confirm-archive-player'),
              onPressed: state.isMutating
                  ? null
                  : () async {
                      final archived = await cubit.archivePlayer(player);
                      if (archived && ctx.mounted) Navigator.pop(ctx);
                    },
              style: AppTheme.primaryButton(
                background: AppColors.error,
                pressed: AppColors.error,
              ),
              icon: state.isMutating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'In corso',
                      ),
                    )
                  : const Icon(Icons.archive_outlined),
              label: const Text('Archivia'),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showAddDialog(BuildContext rootContext) {
  final cubit = rootContext.read<PlayersCubit>();
  showDialog<void>(
    context: rootContext,
    builder: (_) => _PlayerNameDialog(
      title: 'Nuovo giocatore',
      action: 'Aggiungi',
      onSubmit: cubit.addPlayer,
    ),
  );
}

void _showRenameDialog(BuildContext rootContext, Player player) {
  final cubit = rootContext.read<PlayersCubit>();
  showDialog<void>(
    context: rootContext,
    builder: (_) => _PlayerNameDialog(
      title: 'Modifica nome',
      action: 'Salva',
      initialName: player.name,
      onSubmit: (name) => cubit.renamePlayer(player, name),
    ),
  );
}

class _PlayerNameDialog extends StatefulWidget {
  const _PlayerNameDialog({
    required this.title,
    required this.action,
    required this.onSubmit,
    this.initialName = '',
  });
  final String title, action, initialName;
  final Future<bool> Function(String name) onSubmit;
  @override
  State<_PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<_PlayerNameDialog> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialName);
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final success = await widget.onSubmit(_controller.text.trim());
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          enabled: !_busy,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Inserisci un nome.'
              : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'In corso',
                  ),
                )
              : const Icon(Icons.check),
          label: Text(widget.action),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Pill(
            text: '$presentCount/$total presenti',
            color: AppColors.primary,
          ),
          _Pill(
            text: ready
                ? 'Pronti a giocare'
                : 'Servono ${minimumPlayers - presentCount} per giocare',
            color: ready ? AppColors.success : AppColors.ink,
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
    required this.first,
    required this.last,
  });
  final Player player;
  final VoidCallback? onToggle, onRename, onArchive, onReactivate;
  final VoidCallback onOpenProfile;
  final bool first, last;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(first ? AppRadius.panel : 0),
        bottom: Radius.circular(last ? AppRadius.panel : 0),
      ),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Profilo di ${player.name}',
                  value: player.isArchived
                      ? 'Archiviato'
                      : player.isPresent
                      ? 'In ufficio'
                      : 'Assente',
                  onTap: onOpenProfile,
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: onOpenProfile,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          children: [
                            PlayerAvatar(name: player.name, size: 42),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(player.name, style: AppType.player),
                                  const SizedBox(height: 2),
                                  AnimatedSwitcher(
                                    duration: AppMotion.duration(
                                      context,
                                      AppMotion.selection,
                                    ),
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
                          ],
                        ),
                      ),
                    ),
                  ),
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
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _PlayerAction.profile,
                    child: ListTile(
                      leading: Icon(Icons.person_search),
                      title: Text('Profilo'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _PlayerAction.rename,
                    enabled: onRename != null,
                    child: const ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Modifica nome'),
                    ),
                  ),
                  if (player.isArchived)
                    PopupMenuItem(
                      value: _PlayerAction.reactivate,
                      enabled: onReactivate != null,
                      child: const ListTile(
                        leading: Icon(Icons.unarchive),
                        title: Text('Riattiva'),
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: _PlayerAction.archive,
                      enabled: onArchive != null,
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
        if (!last) const Divider(height: 1, indent: 12, endIndent: 12),
      ],
    ),
  );
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
        ? AppColors.success
        : AppColors.textSecondary;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            isArchived
                ? 'Archiviato'
                : isPresent
                ? 'In ufficio'
                : 'Assente',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Nessun giocatore',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Aggiungi il primo player con il pulsante in basso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
  );
}
