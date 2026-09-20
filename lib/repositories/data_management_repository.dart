import '../models/backup_data.dart';

/// Atomic backup boundary and refresh, independently replaceable in tests.
abstract interface class DataManagementRepository {
  bool get needsRefresh;
  Future<DataExport> export({required bool csv});
  Future<BackupData> parse(String source);
  Future<void> restore(BackupData data);
  Future<void> refresh();
}
