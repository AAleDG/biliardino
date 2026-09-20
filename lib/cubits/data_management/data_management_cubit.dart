import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/backup_data.dart';
import '../../repositories/data_management_repository.dart';
import 'data_management_state.dart';
export 'data_management_state.dart';

class DataManagementCubit extends Cubit<DataManagementState> {
  DataManagementCubit(this._repository)
    : super(DataManagementState(refreshRequired: _repository.needsRefresh));
  final DataManagementRepository _repository;
  BackupData? _pending;
  int _effectId = 0;

  bool get _available => !isClosed && !state.busy && !state.refreshRequired;
  bool _accept(int id, DataEffectKind kind) =>
      !isClosed && state.effect?.id == id && state.effect?.kind == kind;
  void _message(String text, {bool refreshRequired = false}) {
    if (isClosed) return;
    emit(
      DataManagementState(
        refreshRequired: refreshRequired,
        effect: DataEffect(++_effectId, DataEffectKind.message, message: text),
      ),
    );
  }

  Future<void> export({required bool csv}) async {
    if (!_available) return;
    emit(const DataManagementState(busy: true));
    try {
      final file = await _repository.export(csv: csv);
      if (isClosed) return;
      emit(
        DataManagementState(
          busy: true,
          effect: DataEffect(++_effectId, DataEffectKind.share, export: file),
        ),
      );
    } on Object {
      _message('Impossibile preparare il file. Riprova.');
    }
  }

  void shareFinished(int id, {required bool succeeded}) {
    if (!_accept(id, DataEffectKind.share)) return;
    _message(
      succeeded
          ? state.effect!.export!.message
          : 'Impossibile condividere il file. Riprova.',
    );
  }

  void restore() {
    if (!_available) return;
    emit(
      DataManagementState(
        busy: true,
        effect: DataEffect(++_effectId, DataEffectKind.pick),
      ),
    );
  }

  Future<void> picked(int id, String? source, {bool failed = false}) async {
    if (!_accept(id, DataEffectKind.pick)) return;
    if (failed) {
      _message('Impossibile aprire il backup selezionato.');
      return;
    }
    if (source == null) {
      emit(const DataManagementState());
      return;
    }
    // Consume the picker effect before yielding so duplicate completions are ignored.
    emit(const DataManagementState(busy: true));
    try {
      final data = await _repository.parse(source);
      if (isClosed) return;
      _pending = data;
      emit(
        DataManagementState(
          busy: true,
          effect: DataEffect(
            ++_effectId,
            DataEffectKind.confirm,
            summary: ImportSummary(
              players: _pending!.players.length,
              matches: _pending!.matches.length,
            ),
          ),
        ),
      );
    } on Object {
      _pending = null;
      _message(
        'Backup non valido o non supportato. I dati locali non sono stati modificati.',
      );
    }
  }

  Future<void> confirmed(int id, bool confirmed) async {
    if (!_accept(id, DataEffectKind.confirm)) return;
    final data = _pending!;
    _pending = null;
    emit(DataManagementState(busy: confirmed));
    if (!confirmed) return;
    try {
      await _repository.restore(data);
    } on Object {
      _message(
        'Ripristino non riuscito. I dati locali non sono stati modificati.',
      );
      return;
    }
    // Refresh even when the route closed during the committed transaction.
    await _refresh();
  }

  Future<void> retryRefresh() async {
    if (isClosed || state.busy || !state.refreshRequired) return;
    emit(const DataManagementState(busy: true, refreshRequired: true));
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      await _repository.refresh();
      _message('Backup ripristinato.');
    } on Object {
      _message(
        'Backup ripristinato, ma la vista non è aggiornata. Riprova ad aggiornare.',
        refreshRequired: true,
      );
    }
  }
}
