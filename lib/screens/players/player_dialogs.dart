import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/players/players_cubit.dart';
import '../../cubits/players/players_state.dart';
import '../../models/player.dart';
import '../../theme/app_theme.dart';

String playersFeedbackText(PlayersFeedback feedback) {
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

void showPlayerArchiveDialog(BuildContext rootContext, Player player) {
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

void showPlayerAddDialog(BuildContext rootContext) {
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

void showPlayerRenameDialog(BuildContext rootContext, Player player) {
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
