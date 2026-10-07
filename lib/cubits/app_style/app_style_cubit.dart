import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/app_style.dart';
import '../../repositories/app_style_repository.dart';

/// Owned above presentation widgets, alongside the application's other Cubits.
class AppStyleCubit extends Cubit<AppStyle> {
  AppStyleCubit(this._repository) : super(_repository.style);
  final AppStyleRepository _repository;
  final _pending = ValueNotifier<AppStyle?>(null);
  ValueListenable<AppStyle?> get pendingSelection => _pending;

  Future<void> select(AppStyle style) async {
    if (isClosed) throw StateError('Style controller is closed.');
    if (_pending.value != null) {
      throw StateError('A style preference is already being saved.');
    }
    _pending.value = style;
    try {
      // Do not skip equal values: an explicit choice replaces an unknown value.
      await _repository.save(style);
      if (!isClosed) emit(style);
    } finally {
      if (!isClosed) _pending.value = null;
    }
  }

  @override
  Future<void> close() async {
    await super.close();
    _pending.dispose();
  }
}
