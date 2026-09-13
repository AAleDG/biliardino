import 'dart:async';
import 'package:biliardino/models/backup_data.dart';
import 'package:biliardino/repositories/data_management_repository.dart';

class FakeData implements DataManagementRepository {
  @override
  bool needsRefresh = false;
  int writes = 0, refreshes = 0, exports = 0;
  bool failWrite = false, failRefresh = false, failExport = false;
  Completer<void>? barrier;
  @override
  Future<DataExport> export({required bool csv}) async {
    exports++;
    await barrier?.future;
    if (failExport) throw StateError('export');
    return const DataExport(
      content: '{}',
      fileName: 'backup.json',
      mimeType: 'application/json',
      subject: 'Backup',
      message: 'Pronto',
    );
  }

  @override
  BackupData parse(String source) {
    if (source == 'bad') throw const FormatException();
    return const BackupData(players: [], matches: []);
  }

  @override
  Future<void> restore(BackupData data) async {
    writes++;
    await barrier?.future;
    if (failWrite) throw StateError('write');
    needsRefresh = true;
  }

  @override
  Future<void> refresh() async {
    refreshes++;
    if (failRefresh) throw StateError('refresh');
    needsRefresh = false;
  }
}
