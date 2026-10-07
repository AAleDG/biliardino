import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/data_management/data_management_cubit.dart';
import '../../../data/database_helper.dart';
import '../../../repositories/data_management_repository.dart';
import '../../../repositories/match_repository.dart';
import '../../../repositories/player_repository.dart';
import '../../../services/backup_file_picker.dart';
import '../theme/italia90_tokens.dart';
import '../../../services/data_backup_service.dart';
import '../../../services/data_file_share_service.dart';
import '../widgets/italia90_components.dart';
import '../widgets/italia90_page.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({
    super.key,
    this.repository,
    this.showBack = true,
  });

  final DataManagementRepository? repository;
  final bool showBack;

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final DataBackupService _backup = DataBackupService(DatabaseHelper.instance);
  final DataFileShareService _files = DataFileShareService.platform();
  final BackupFilePicker _picker = const BackupFilePicker();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository ?? _tryReadRepository(context);
    if (repository != null) {
      return BlocProvider<DataManagementCubit>(
        create: (_) => DataManagementCubit(repository),
        child: _DataView(showBack: widget.showBack),
      );
    }
    return _buildLegacyView(context);
  }

  Widget _buildLegacyView(BuildContext context) {
    return ItaliaPage(
      title: 'DATI',
      showBack: widget.showBack,
      mastheadKey: const ValueKey('data-masthead'),
      footballKey: const ValueKey('data-brand-football'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const _BackupIntroduction(),
          const SizedBox(height: 20),
          const Text('ESPORTA', style: Italia90.heading),
          const SizedBox(height: 12),
          ItaliaDataActionSlip(
            key: const ValueKey('export-json'),
            icon: Icons.cloud_upload_outlined,
            title: 'Crea backup',
            subtitle: 'Giocatori e partite da ripristinare',
            onPressed: _busy ? null : _exportJson,
          ),
          ItaliaDataActionSlip(
            key: const ValueKey('export-csv'),
            icon: Icons.table_view_outlined,
            title: 'Esporta risultati',
            subtitle: 'Per un foglio di calcolo',
            onPressed: _busy ? null : _exportCsv,
          ),
          const SizedBox(height: 18),
          const Text('RIPRISTINA', style: Italia90.heading),
          const SizedBox(height: 16),
          ItaliaDataActionSlip(
            key: const ValueKey('restore-json'),
            icon: Icons.restore,
            title: 'Ripristina backup',
            subtitle: 'Sostituisce i dati dopo la conferma',
            onPressed: _busy ? null : _restore,
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            Semantics(
              liveRegion: true,
              label: 'Operazione in corso',
              child: const Center(
                child: ItaliaPanel(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  DataManagementRepository? _tryReadRepository(BuildContext context) {
    try {
      return context.read<DataManagementRepository>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<void> _exportJson() async {
    await _run(() async {
      final now = DateTime.now();
      final json = await _backup.createJson(now);
      await _files.share(
        content: json,
        fileName:
            'biliardino_backup_${DateFormat('yyyyMMdd_HHmmss').format(now)}.json',
        mimeType: 'application/json',
        subject: 'Backup Biliardino',
        sharePositionOrigin: _shareOrigin(),
      );
      _message('Backup pronto per il salvataggio o la condivisione.');
    });
  }

  Future<void> _exportCsv() async {
    await _run(() async {
      final now = DateTime.now();
      final players = await DatabaseHelper.instance.getPlayers();
      final matches = await DatabaseHelper.instance.getMatches();
      final csv = MatchHistoryCsvService.build(players, matches);
      await _files.share(
        content: csv,
        fileName:
            'storico_biliardino_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv',
        mimeType: 'text/csv',
        subject: 'Storico Biliardino',
        sharePositionOrigin: _shareOrigin(),
      );
      _message('CSV pronto per il salvataggio o la condivisione.');
    });
  }

  Future<void> _restore() async {
    final String? source;
    try {
      source = await _picker.pickJson();
    } on BackupFilePickerException {
      _message('Impossibile aprire il backup selezionato.');
      return;
    }
    if (source == null) return;
    final backupSource = source;
    await _run(() async {
      final data = _backup.parse(backupSource);
      final summary = _backup.summarize(data);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ripristinare il backup?'),
          content: Text(
            'Il backup contiene ${summary.players} giocatori e '
            '${summary.matches} partite. I dati locali verranno sostituiti.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ripristina'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _backup.restore(data);
      if (!mounted) return;
      await Future.wait([
        context.read<PlayerRepository>().load(),
        context.read<MatchRepository>().load(),
      ]);
      _message('Backup ripristinato.');
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
    } on Object {
      _message(
        'Operazione non riuscita. I dati locali non sono stati modificati.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DataView extends StatelessWidget {
  const _DataView({required this.showBack});

  final bool showBack;

  Future<void> _effect(BuildContext context, DataEffect effect) async {
    final cubit = context.read<DataManagementCubit>();
    switch (effect.kind) {
      case DataEffectKind.pick:
        try {
          final source = await context.read<BackupFilePicker>().pickJson();
          cubit.picked(effect.id, source);
        } on Object {
          cubit.picked(effect.id, null, failed: true);
        }
      case DataEffectKind.share:
        final file = effect.export!;
        final box = context.findRenderObject() as RenderBox?;
        try {
          await context.read<DataFileShareService>().share(
            content: file.content,
            fileName: file.fileName,
            mimeType: file.mimeType,
            subject: file.subject,
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          );
          cubit.shareFinished(effect.id, succeeded: true);
        } on Object {
          cubit.shareFinished(effect.id, succeeded: false);
        }
      case DataEffectKind.confirm:
        final summary = effect.summary!;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Ripristinare il backup?'),
            content: Text(
              'Il backup contiene ${summary.players} giocatori e '
              '${summary.matches} partite. I dati locali verranno sostituiti.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Ripristina'),
              ),
            ],
          ),
        );
        await cubit.confirmed(effect.id, confirmed == true);
      case DataEffectKind.message:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(effect.message!)));
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DataManagementCubit, DataManagementState>(
        listenWhen: (previous, current) =>
            current.effect != null && previous.effect?.id != current.effect!.id,
        listener: (context, state) => _effect(context, state.effect!),
        builder: (context, state) {
          final cubit = context.read<DataManagementCubit>();
          final enabled = !state.busy && !state.refreshRequired;
          return PopScope(
            canPop: !state.busy,
            child: ItaliaPage(
              title: 'DATI',
              showBack: showBack,
              mastheadKey: const ValueKey('data-masthead'),
              footballKey: const ValueKey('data-brand-football'),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  const _BackupIntroduction(),
                  const SizedBox(height: 20),
                  const Text('ESPORTA', style: Italia90.heading),
                  const SizedBox(height: 12),
                  ItaliaDataActionSlip(
                    key: const ValueKey('export-json'),
                    icon: Icons.cloud_upload_outlined,
                    title: 'Crea backup',
                    subtitle: 'Giocatori e partite da ripristinare',
                    onPressed: enabled ? () => cubit.export(csv: false) : null,
                  ),
                  ItaliaDataActionSlip(
                    key: const ValueKey('export-csv'),
                    icon: Icons.table_view_outlined,
                    title: 'Esporta risultati',
                    subtitle: 'Per un foglio di calcolo',
                    onPressed: enabled ? () => cubit.export(csv: true) : null,
                  ),
                  const SizedBox(height: 18),
                  const Text('RIPRISTINA', style: Italia90.heading),
                  const SizedBox(height: 16),
                  ItaliaDataActionSlip(
                    key: const ValueKey('restore-json'),
                    icon: Icons.restore,
                    title: 'Ripristina backup',
                    subtitle: 'Sostituisce i dati dopo la conferma',
                    onPressed: enabled ? cubit.restore : null,
                  ),
                  if (state.busy) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      liveRegion: true,
                      label: 'Operazione in corso',
                      child: const Center(
                        child: ItaliaPanel(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],
                  if (state.refreshRequired && !state.busy)
                    TextButton(
                      onPressed: cubit.retryRefresh,
                      child: const Text('Riprova ad aggiornare'),
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class _BackupIntroduction extends StatelessWidget {
  const _BackupIntroduction();

  @override
  Widget build(BuildContext context) => const Text(
    'Proteggi i tuoi giocatori e le tue partite con un backup, oppure ripristina una copia precedente.',
    key: ValueKey('data-introduction'),
    style: Italia90.body,
  );
}
