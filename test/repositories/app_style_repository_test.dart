import 'package:biliardino/data/database_helper.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/repositories/app_style_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../support/fake_database.dart';

void main() {
  test(
    'missing and unavailable preferences default without rewriting storage',
    () async {
      for (final raw in [null, 'future-style', '']) {
        final db = FakeDatabaseHelper();
        if (raw != null) db.settings[AppStyleRepository.storageKey] = raw;
        final before = Map<String, String>.of(db.settings);
        final repo = AppStyleRepository(db);
        await repo.load();
        expect(repo.style, AppStyle.southAfrica2010);
        expect(db.settings, before);
      }
      expect(AppStyle.values, [AppStyle.southAfrica2010, AppStyle.italia90]);
    },
  );

  test(
    'explicit selection persists across repository recreation, preserving other settings',
    () async {
      sqfliteFfiInit();
      final database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );
      addTearDown(database.close);
      await database.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      final db = DatabaseHelper.withDatabase(database);
      await db.setSettings({
        'match_rules.target_score': '12',
        AppStyleRepository.storageKey: 'future-style',
      });
      final first = AppStyleRepository(db);
      await first.load();
      await first.save(AppStyle.southAfrica2010);
      await first.save(AppStyle.italia90);
      final second = AppStyleRepository(db);
      await second.load();
      expect(second.style, AppStyle.italia90);
      expect(
        await db.getSettings([
          'match_rules.target_score',
          AppStyleRepository.storageKey,
        ]),
        {
          'match_rules.target_score': '12',
          AppStyleRepository.storageKey: 'italia-90',
        },
      );
    },
  );

  test(
    'read and write errors propagate and leave stored preference intact',
    () async {
      final db = _FailingSettings()
        ..settings[AppStyleRepository.storageKey] = 'future-style';
      final repo = AppStyleRepository(db);
      db.failRead = true;
      await expectLater(repo.load(), throwsStateError);
      db.failRead = false;
      await repo.load();
      await expectLater(repo.save(AppStyle.southAfrica2010), throwsStateError);
      expect(repo.style, AppStyle.southAfrica2010);
      expect(db.settings[AppStyleRepository.storageKey], 'future-style');
    },
  );
}

class _FailingSettings extends FakeDatabaseHelper {
  bool failRead = false;
  @override
  Future<Map<String, String>> getSettings(List<String> keys) {
    if (failRead) throw StateError('read failed');
    return super.getSettings(keys);
  }

  @override
  Future<void> setSettings(Map<String, String> values) async =>
      throw StateError('write failed');
}
