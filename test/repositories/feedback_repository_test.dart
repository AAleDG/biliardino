import 'dart:async';
import 'dart:io';

import 'package:biliardino/data/database_helper.dart';
import 'package:biliardino/models/feedback_draft.dart';
import 'package:biliardino/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'draft survives database close/reopen and preserves unrelated settings',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'feedback-draft-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/draft.db';
      var db = await databaseFactoryFfi.openDatabase(path);
      await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      var helper = DatabaseHelper.withDatabase(db);
      await helper.setSettings({
        'appearance.style': 'italia-90',
        'match_rules.target_score': '12',
      });
      const draft = FeedbackDraft(
        message: '  Messaggio\ncon accenti è ⚽  ',
        email: 'me@example.com',
      );
      await FeedbackRepository(helper).saveDraft(draft);
      await db.close();
      db = await databaseFactoryFfi.openDatabase(path);
      addTearDown(db.close);
      helper = DatabaseHelper.withDatabase(db);
      final restored = await FeedbackRepository(helper).loadDraft();
      expect(restored.toJson(), draft.toJson());
      await FeedbackRepository(helper).clearDraft();
      expect((await FeedbackRepository(helper).loadDraft()).toJson(), {
        'message': '',
        'email': '',
      });
      expect(
        await helper.getSettings([
          'appearance.style',
          'match_rules.target_score',
        ]),
        {'appearance.style': 'italia-90', 'match_rules.target_score': '12'},
      );
    },
  );

  test(
    'clear waits for delayed saves and later route loads cannot resurrect the sent draft',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      final helper = _DelayedDatabase(db);
      final repository = FeedbackRepository(helper);
      final first = repository.saveDraft(const FeedbackDraft(message: 'old'));
      final second = repository.saveDraft(const FeedbackDraft(message: 'sent'));
      final clear = repository.clearDraft();
      final load = repository.loadDraft();
      helper.release.complete();
      await Future.wait([first, second, clear]);
      expect((await load).message, '');
      expect((await FeedbackRepository(helper).loadDraft()).message, '');
    },
  );

  test(
    'real SQLite write failure is reported and queue recovers; corrupt drafts are not overwritten',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      final helper = DatabaseHelper.withDatabase(db);
      final repository = FeedbackRepository(helper);
      await db.execute(
        "CREATE TRIGGER fail_feedback BEFORE INSERT ON settings WHEN NEW.key = 'feedback.draft.v1' BEGIN SELECT RAISE(ABORT, 'storage unavailable'); END",
      );
      await expectLater(
        repository.saveDraft(const FeedbackDraft(message: 'keep')),
        throwsA(isA<DatabaseException>()),
      );
      await db.execute('DROP TRIGGER fail_feedback');
      await repository.saveDraft(const FeedbackDraft(message: 'recovered'));
      expect((await repository.loadDraft()).message, 'recovered');
      await helper.setSettings({FeedbackRepository.storageKey: '{broken'});
      await expectLater(repository.loadDraft(), throwsFormatException);
      expect(
        (await helper.getSettings([
          FeedbackRepository.storageKey,
        ]))[FeedbackRepository.storageKey],
        '{broken',
      );
    },
  );
}

class _DelayedDatabase extends DatabaseHelper {
  _DelayedDatabase(super.database) : super.withDatabase();
  final release = Completer<void>();
  @override
  Future<void> setSettings(Map<String, String> values) async {
    await release.future;
    await super.setSettings(values);
  }
}
