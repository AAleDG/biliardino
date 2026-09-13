import '../../models/backup_data.dart';

enum DataEffectKind { pick, confirm, share, message }

class DataEffect {
  const DataEffect(
    this.id,
    this.kind, {
    this.export,
    this.summary,
    this.message,
  });
  final int id;
  final DataEffectKind kind;
  final DataExport? export;
  final ImportSummary? summary;
  final String? message;
}

class DataManagementState {
  const DataManagementState({
    this.busy = false,
    this.refreshRequired = false,
    this.effect,
  });
  final bool busy, refreshRequired;
  final DataEffect? effect;
}
