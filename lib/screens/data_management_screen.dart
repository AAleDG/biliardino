import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../data/database_helper.dart';
import '../repositories/match_repository.dart';
import '../repositories/player_repository.dart';
import '../services/backup_file_picker.dart';
import '../services/data_backup_service.dart';
import '../services/data_file_share_service.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('DATI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Backup e ripristino',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esporta tutti i giocatori e le partite, oppure ripristina un backup verificato.',
          ),
          const SizedBox(height: 20),
          _ActionTile(
            key: const ValueKey('export-json'),
            icon: Icons.backup_outlined,
            title: 'Esporta backup JSON',
            subtitle: 'File versionato per un ripristino futuro',
            onTap: _busy ? null : _exportJson,
          ),
          _ActionTile(
            key: const ValueKey('export-csv'),
            icon: Icons.table_view_outlined,
            title: 'Esporta storico CSV',
            subtitle: 'Risultati leggibili in un foglio di calcolo',
            onTap: _busy ? null : _exportCsv,
          ),
          _ActionTile(
            key: const ValueKey('restore-json'),
            icon: Icons.restore,
            title: 'Ripristina backup JSON',
            subtitle:
                'Il contenuto viene verificato prima di sostituire i dati',
            onTap: _busy ? null : _restore,
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            Semantics(
              liveRegion: true,
              label: 'Operazione in corso',
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ],
      ),
    );
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      enabled: onTap != null,
      onTap: onTap,
    ),
  );
}
