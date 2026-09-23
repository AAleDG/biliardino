import 'dart:async';
import 'package:biliardino/cubits/app_style/app_style_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/repositories/app_style_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_database.dart';

void main() {
  test(
    'save failures remain observable and a subsequent selection can retry',
    () async {
      final db = _DelayedSettings()..fail = true;
      final cubit = AppStyleCubit(AppStyleRepository(db));
      addTearDown(cubit.close);
      await expectLater(
        cubit.select(AppStyle.southAfrica2010),
        throwsStateError,
      );
      expect(db.settings, isEmpty);
      db.fail = false;
      await cubit.select(AppStyle.southAfrica2010);
      expect(db.settings[AppStyleRepository.storageKey], 'south-africa-2010');
    },
  );

  test(
    'overlapping saves are rejected and completion after disposal does not emit',
    () async {
      final db = _DelayedSettings()..barrier = Completer<void>();
      final cubit = AppStyleCubit(AppStyleRepository(db));
      final saving = cubit.select(AppStyle.southAfrica2010);
      await expectLater(
        cubit.select(AppStyle.southAfrica2010),
        throwsStateError,
      );
      await cubit.close();
      db.barrier!.complete();
      await saving;
      expect(db.settings[AppStyleRepository.storageKey], 'south-africa-2010');
      await expectLater(
        cubit.select(AppStyle.southAfrica2010),
        throwsStateError,
      );
    },
  );
}

class _DelayedSettings extends FakeDatabaseHelper {
  bool fail = false;
  Completer<void>? barrier;
  @override
  Future<void> setSettings(Map<String, String> values) async {
    await barrier?.future;
    if (fail) throw StateError('write failed');
    await super.setSettings(values);
  }
}
