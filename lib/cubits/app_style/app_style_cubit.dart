import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/app_style.dart';
import '../../repositories/app_style_repository.dart';

/// Owned above presentation widgets, alongside the application's other Cubits.
class AppStyleCubit extends Cubit<AppStyle> {
  AppStyleCubit(this._repository) : super(_repository.style);
  final AppStyleRepository _repository;
  bool _saving = false;

  Future<void> select(AppStyle style) async {
    if (isClosed) throw StateError('Style controller is closed.');
    if (_saving) throw StateError('A style preference is already being saved.');
    _saving = true;
    try {
      // Do not skip equal values: an explicit choice replaces an unknown value.
      await _repository.save(style);
      if (!isClosed) emit(style);
    } finally {
      _saving = false;
    }
  }
}
