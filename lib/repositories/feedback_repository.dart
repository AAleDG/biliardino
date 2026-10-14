import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

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
  static const deliveryKey = 'feedback.delivery.v1';
  final DatabaseHelper _database;
  final FormspreeFeedback _transport;
  final Future<FeedbackContext> Function() _contextLoader;
  Future<void> _writes = Future<void>.value();

  String? _acknowledgedAttempt;
  String? _failedAttempt;

  Future<FeedbackDraft> loadDraft() async {
    await _writes;
    final settings = await _database.getSettings([storageKey, deliveryKey]);
    final journal = jsonDecode(settings[deliveryKey] ?? 'null');
    if (journal != null) {
      if (journal is! Map<String, dynamic> ||
          journal['id'] is! String ||
          !['pending', 'sent'].contains(journal['status'])) {
        throw const FormatException('Invalid feedback delivery record');
      }
      if (journal['status'] == 'sent' ||
          journal['id'] == _acknowledgedAttempt) {
        return const FeedbackDraft();
      }
    }
    final raw = settings[storageKey];
    if (raw == null) return const FeedbackDraft();
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid feedback draft');
    }
    final draft = FeedbackDraft.fromJson(json);
    if (journal != null && journal['id'] != _failedAttempt) {
      throw FeedbackRecoveryRequired(draft);
    }
    return draft;
  }

  Future<void> _write(Map<String, String> values) {
    final write = _writes.then((_) => _database.setSettings(values));
    // Keep the queue usable after a failure; the caller still receives it.
    _writes = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }

  Future<void> saveDraft(FeedbackDraft draft) =>
      _write({storageKey: jsonEncode(draft.toJson()), deliveryKey: 'null'});

  Future<void> clearDraft() => saveDraft(const FeedbackDraft());

  /// Explicit recovery must retire the uncertain attempt before enabling Send.
  Future<void> restoreDraft(FeedbackDraft draft) => saveDraft(draft);

  Future<void> send(FeedbackDraft draft, AppStyle style) async {
    // Metadata is loaded only for feedback, never during game bootstrap.
    final context = await _contextLoader().timeout(const Duration(seconds: 5));
    final id = const Uuid().v4();
    // Commit before dispatch: later receipt/cleanup failures leave uncertainty
    // on disk rather than an ordinary sendable draft after restart.
    await _write({
      storageKey: jsonEncode(draft.toJson()),
      deliveryKey: jsonEncode({'id': id, 'status': 'pending'}),
    }).timeout(const Duration(seconds: 5));
    try {
      await _transport.send(draft, context, style);
    } on Object {
      _failedAttempt = id;
      try {
        await _write({deliveryKey: 'null'}).timeout(const Duration(seconds: 5));
      } on Object {
        // Manual retry remains available in this process. Restart must warn
        // if no acknowledgement or retirement survived on disk.
      }
      rethrow;
    }
    _acknowledgedAttempt = id;
    try {
      await _write({
        deliveryKey: jsonEncode({'id': id, 'status': 'sent'}),
      }).timeout(const Duration(seconds: 5));
    } on Object {
      // Receipt stays truthful. Pending disk record blocks implicit restoration;
      // memory suppresses it on another visit in this process.
    }
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

/// No acknowledgement survived on disk. Restoring is deliberate because the
/// provider may already have received this message.
class FeedbackRecoveryRequired extends StateError {
  FeedbackRecoveryRequired(this.draft)
    : super('Feedback delivery is uncertain');
  final FeedbackDraft draft;
}
