import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/database_helper.dart';
import '../models/app_style.dart';
import '../models/feedback_draft.dart';
import '../services/formspree_feedback.dart';

/// One local draft across styles. Writes share a queue across route visits,
/// including clearing after delivery, so earlier saves cannot resurrect it.
class FeedbackRepository {
  FeedbackRepository(
    this._database, {
    FormspreeFeedback? transport,
    Future<FeedbackContext> Function()? contextLoader,
  }) : _transport = transport ?? FormspreeFeedback(),
       _contextLoader = contextLoader ?? _loadContext;

  static const storageKey = 'feedback.draft.v1';
  final DatabaseHelper _database;
  final FormspreeFeedback _transport;
  final Future<FeedbackContext> Function() _contextLoader;
  Future<void> _writes = Future<void>.value();

  Future<FeedbackDraft> loadDraft() async {
    await _writes;
    final settings = await _database.getSettings([storageKey]);
    final raw = settings[storageKey];
    if (raw == null) return const FeedbackDraft();
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid feedback draft');
    }
    return FeedbackDraft.fromJson(json);
  }

  Future<void> saveDraft(FeedbackDraft draft) {
    final write = _writes.then(
      (_) => _database.setSettings({storageKey: jsonEncode(draft.toJson())}),
    );
    // Keep the queue usable after a failure; the caller still receives it.
    _writes = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }

  Future<void> clearDraft() => saveDraft(const FeedbackDraft());

  Future<void> send(FeedbackDraft draft, AppStyle style) async {
    // Metadata is loaded only for feedback, never during game bootstrap.
    final context = await _contextLoader().timeout(const Duration(seconds: 5));
    await _transport.send(draft, context, style);
  }

  static Future<FeedbackContext> _loadContext() async {
    final package = await PackageInfo.fromPlatform();
    return FeedbackContext(
      version: package.version,
      build: package.buildNumber,
      platform: switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'iOS',
        TargetPlatform.android => 'Android',
        _ => defaultTargetPlatform.name,
      },
    );
  }
}
