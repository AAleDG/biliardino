import 'dart:async';
import 'dart:io';

import 'package:biliardino/data/database_helper.dart';
import 'package:biliardino/cubits/feedback/feedback_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/services/formspree_feedback.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:biliardino/models/feedback_draft.dart';
import 'package:biliardino/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'acknowledged feedback cannot return as a sendable draft after failed cleanup and restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'feedback-receipt-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/draft.db';
      var db = await databaseFactoryFfi.openDatabase(path);
      await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      final repository = FeedbackRepository(
        DatabaseHelper.withDatabase(db),
        contextLoader: () async =>
            const FeedbackContext(version: '1', build: '1', platform: 'iOS'),
        transport: FormspreeFeedback(
          clientFactory: () => MockClient((_) async {
            await db.execute(
              "CREATE TRIGGER fail_cleanup BEFORE INSERT ON settings BEGIN SELECT RAISE(ABORT, 'storage unavailable'); END",
            );
            return http.Response(
              '{"next":"/thanks"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      await repository.saveDraft(
        const FeedbackDraft(message: 'Already delivered'),
      );
      final cubit = FeedbackCubit(repository);
      await cubit.load();
      await cubit.send(AppStyle.italia90);
      expect(cubit.state.status, FeedbackStatus.sent);
      expect(cubit.state.draftNotice, isNotNull);
      expect((await repository.loadDraft()).message, '');
      await cubit.close();
      await db.close();
      db = await databaseFactoryFfi.openDatabase(path);
      addTearDown(db.close);
      final restarted = FeedbackRepository(DatabaseHelper.withDatabase(db));
      await expectLater(
        restarted.loadDraft(),
        throwsA(isA<FeedbackRecoveryRequired>()),
      );
      final recovery = FeedbackCubit(restarted);
      addTearDown(recovery.close);
      await recovery.load();
      expect(recovery.state.status, FeedbackStatus.recovery);
      await recovery.restoreDraft();
      expect(recovery.state.status, FeedbackStatus.recovery);
      await db.execute('DROP TRIGGER fail_cleanup');
      await recovery.restoreDraft();
      expect(recovery.state.status, FeedbackStatus.editing);
      expect(recovery.state.draft.message, 'Already delivered');
      expect(
        (await FeedbackRepository(
          DatabaseHelper.withDatabase(db),
        ).loadDraft()).message,
        'Already delivered',
      );
    },
  );

  test(
    'failed journal transaction prevents dispatch and preserves the previous draft',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      var requests = 0;
      final repository = FeedbackRepository(
        DatabaseHelper.withDatabase(db),
        contextLoader: () async =>
            const FeedbackContext(version: '1', build: '1', platform: 'iOS'),
        transport: FormspreeFeedback(
          clientFactory: () => MockClient((_) async {
            requests++;
            return http.Response(
              '{"next":"/thanks"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      await repository.saveDraft(const FeedbackDraft(message: 'previous'));
      await db.execute(
        "CREATE TRIGGER fail_journal BEFORE INSERT ON settings WHEN NEW.key = 'feedback.delivery.v1' BEGIN SELECT RAISE(ABORT, 'storage unavailable'); END",
      );
      await expectLater(
        repository.send(
          const FeedbackDraft(message: 'unsaved change'),
          AppStyle.italia90,
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(requests, 0);
      expect(
        (await FeedbackRepository(
          DatabaseHelper.withDatabase(db),
        ).loadDraft()).message,
        'previous',
      );
    },
  );

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
