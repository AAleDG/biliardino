import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../repositories/data_management_repository.dart';
import 'data_backup_service.dart';

class DataManagementCoordinator implements DataManagementRepository {
  // Named callback keeps repository refresh injection explicit at composition.
  DataManagementCoordinator({
    required DatabaseHelper database,
    required Future<void> Function() refresh,
    DateTime Function()? clock,
  }) : _database = database,
       _backup = DataBackupService(database),
       // ignore: prefer_initializing_formals
       _refresh = refresh,
       _clock = clock ?? DateTime.now;
  final DatabaseHelper _database;
  final DataBackupService _backup;
  final Future<void> Function() _refresh;
  final DateTime Function() _clock;
  bool _needsRefresh = false;
  @override
  bool get needsRefresh => _needsRefresh;

  @override
  Future<DataExport> export({required bool csv}) async {
    final now = _clock();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final content = csv
        ? MatchHistoryCsvService.build(
            await _database.getPlayers(),
            await _database.getMatches(),
          )
        : await _backup.createJson(now);
    return DataExport(
      content: content,
      fileName: csv
          ? 'storico_biliardino_$stamp.csv'
          : 'biliardino_backup_$stamp.json',
      mimeType: csv ? 'text/csv' : 'application/json',
      subject: csv ? 'Storico Biliardino' : 'Backup Biliardino',
      message: csv
          ? 'CSV pronto per il salvataggio o la condivisione.'
          : 'Backup pronto per il salvataggio o la condivisione.',
    );
  }

  @override
  Future<BackupData> parse(String source) =>
      compute(DataBackupService.parseJson, source, debugLabel: 'backup-parse');
  @override
  Future<void> restore(BackupData data) async {
    await _backup.restore(data);
    _needsRefresh = true;
  }

  @override
  Future<void> refresh() async {
    await _refresh();
    _needsRefresh = false;
  }
}
