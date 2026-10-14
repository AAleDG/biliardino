import 'dart:async';
import 'dart:convert';

import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/models/feedback_draft.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/presentation/presentation_host.dart';
import 'package:biliardino/repositories/feedback_repository.dart';
import 'package:biliardino/screens/feedback/feedback_screen.dart';
import 'package:biliardino/services/formspree_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/design_fixture.dart';

void main() {
  for (final style in AppStyle.values) {
    testWidgets(
      'feedback fields keep associated accessible labels in ${style.storageValue}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _open(tester, style: style, handler: (_) async => _ack());
          final message = find.byKey(const ValueKey('feedback-message'));
          final email = find.byKey(const ValueKey('feedback-email'));
          void expectFieldLabels() {
            final messageData = tester.getSemantics(message).getSemanticsData();
            final emailData = tester.getSemantics(email).getSemanticsData();
            expect(messageData.flagsCollection.isTextField, isTrue);
            expect(emailData.flagsCollection.isTextField, isTrue);
            expect(messageData.label, contains('Messaggio (obbligatorio)'));
            expect(emailData.label, contains('Email (facoltativa)'));
          }

          expectFieldLabels();
          await tester.enterText(message, 'Una proposta');
          await tester.enterText(email, 'person@example.com');
          await tester.pumpAndSettle();
          expectFieldLabels();
          expect(
            tester.getSemantics(message).getSemanticsData().value,
            'Una proposta',
          );
          expect(
            tester.getSemantics(email).getSemanticsData().value,
            'person@example.com',
          );
          await tester.enterText(message, '');
          await tester.enterText(email, 'invalid');
          await _tap(tester, find.byKey(const ValueKey('feedback-send')));
          expectFieldLabels();
          expect(
            tester.getSemantics(message).getSemanticsData().hint,
            contains('Scrivi un messaggio.'),
          );
          expect(
            tester.getSemantics(email).getSemanticsData().hint,
            contains('Inserisci un’email valida.'),
          );
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'uncertain delivery warns before explicit restore and never sends automatically',
    (tester) async {
      var requests = 0;
      final fixture = await _open(
        tester,
        handler: (_) async {
          requests++;
          return _ack();
        },
      );
      await Navigator.of(
        tester.element(find.byType(FeedbackScreen)),
      ).maybePop();
      await tester.pumpAndSettle();
      await fixture.database.setSettings({
        FeedbackRepository.storageKey: jsonEncode(
          const FeedbackDraft(message: 'Possible duplicate').toJson(),
        ),
        FeedbackRepository.deliveryKey: jsonEncode({
          'id': 'interrupted',
          'status': 'pending',
        }),
      });
      await _tap(tester, find.byKey(const ValueKey('more-feedback')));
      expect(
        find.textContaining('potresti duplicare il feedback'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('feedback-send')), findsNothing);
      final repository = fixture.feedbackRepository as _StorageRepository;
      repository.failSave = true;
      await _tap(tester, find.text('Ripristina bozza'));
      expect(
        find.text('Non siamo riusciti a ripristinare la bozza. Riprova.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('feedback-send')), findsNothing);
      // Closing preserves the warning on the next visit.
      await Navigator.of(
        tester.element(find.byType(FeedbackScreen)),
      ).maybePop();
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('more-feedback')));
      repository.failSave = false;
      await _tap(tester, find.text('Ripristina bozza'));
      expect(_message(tester), 'Possible duplicate');
      expect(find.byKey(const ValueKey('feedback-send')), findsOneWidget);
      expect(requests, 0);
    },
  );

  testWidgets(
    'required message and optional valid email validate before any send',
    (tester) async {
      var requests = 0;
      await _open(
        tester,
        handler: (_) async {
          requests++;
          return _ack();
        },
      );
      await _tap(tester, find.byKey(const ValueKey('feedback-send')));
      expect(find.text('Scrivi un messaggio.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('feedback-message')),
        'Un’idea',
      );
      for (final invalid in ['invalid', 'a@.', 'a@b.', 'a@b..c']) {
        await tester.enterText(
          find.byKey(const ValueKey('feedback-email')),
          invalid,
        );
        await _tap(tester, find.byKey(const ValueKey('feedback-send')));
        expect(find.text('Inserisci un’email valida.'), findsOneWidget);
        expect(requests, 0);
      }
      await tester.enterText(find.byKey(const ValueKey('feedback-email')), '');
      await _tap(tester, find.byKey(const ValueKey('feedback-send')));
      expect(requests, 1);
      expect(find.text('Grazie! Feedback inviato.'), findsOneWidget);
    },
  );

  testWidgets(
    'single-flight send blocks Back/editing, failure waits for retry, success returns and clears',
    (tester) async {
      var requests = 0;
      var result = Completer<http.Response>();
      await _open(
        tester,
        handler: (_) {
          requests++;
          return result.future;
        },
      );
      await tester.enterText(
        find.byKey(const ValueKey('feedback-message')),
        'Una proposta',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-send')));
      await tester.tap(find.byKey(const ValueKey('feedback-send')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(requests, 1);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('feedback-send')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('feedback-message')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('feedback-email')))
            .enabled,
        isFalse,
      );
      await Navigator.of(
        tester.element(find.byType(FeedbackScreen)),
      ).maybePop();
      await tester.pump();
      expect(find.byType(FeedbackScreen), findsOneWidget);
      result.complete(
        http.Response(
          '{"error":"unavailable"}',
          503,
          headers: {'content-type': 'application/json'},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Non siamo riusciti a inviare. Riprova.'),
        findsOneWidget,
      );
      expect(_message(tester), 'Una proposta');
      await tester.pump(const Duration(seconds: 30));
      expect(requests, 1);
      result = Completer<http.Response>();
      await tester.tap(find.byKey(const ValueKey('feedback-send')));
      await tester.pump();
      expect(requests, 2);
      result.complete(_ack());
      await tester.pumpAndSettle();
      expect(find.text('Grazie! Feedback inviato.'), findsOneWidget);
      await _tap(tester, find.text('Torna ad Altro'));
      expect(find.byType(FeedbackScreen), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('more-feedback')));
      expect(_message(tester), '');
    },
  );

  testWidgets(
    'timeout unlocks Back and keeps the message for a deliberate retry',
    (tester) async {
      final pending = Completer<http.Response>();
      await _open(tester, handler: (_) => pending.future);
      await tester.enterText(
        find.byKey(const ValueKey('feedback-message')),
        'Keep this',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-send')));
      await tester.tap(find.byKey(const ValueKey('feedback-send')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(
        find.text('Non siamo riusciti a inviare. Riprova.'),
        findsOneWidget,
      );
      expect(_message(tester), 'Keep this');
      await Navigator.of(
        tester.element(find.byType(FeedbackScreen)),
      ).maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackScreen), findsNothing);
    },
  );

  testWidgets('failed draft load keeps the form closed until retry succeeds', (
    tester,
  ) async {
    final fixture = await _open(
      tester,
      handler: (_) async => _ack(),
      failLoad: true,
    );
    expect(
      find.text('Non siamo riusciti a recuperare la bozza. Riprova.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('feedback-message')), findsNothing);
    expect(find.byKey(const ValueKey('feedback-send')), findsNothing);
    final repository = fixture.feedbackRepository! as _StorageRepository;
    repository.failLoad = false;
    await repository.saveDraft(
      const FeedbackDraft(message: 'Bozza precedente', email: 'a@example.com'),
    );
    await _tap(tester, find.text('Riprova'));
    expect(_message(tester), 'Bozza precedente');
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('feedback-email')))
          .controller!
          .text,
      'a@example.com',
    );
  });

  testWidgets(
    'failed local save is truthful and closing can recover the draft',
    (tester) async {
      final fixture = await _open(
        tester,
        handler: (_) async => _ack(),
        failSave: true,
      );
      await tester.enterText(
        find.byKey(const ValueKey('feedback-message')),
        'Da conservare',
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Non siamo riusciti a salvare la bozza su questo dispositivo.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('La bozza resta salvata su questo dispositivo.'),
        findsNothing,
      );
      await Navigator.of(
        tester.element(find.byType(FeedbackScreen)),
      ).maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Bozza non salvata'), findsOneWidget);
      await _tap(tester, find.text('Resta'));
      expect(_message(tester), 'Da conservare');
      (fixture.feedbackRepository! as _StorageRepository).failSave = false;
      await Navigator.of(
        tester.element(find.byType(FeedbackScreen)),
      ).maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackScreen), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('more-feedback')));
      expect(_message(tester), 'Da conservare');
    },
  );

  testWidgets(
    'late draft persistence updates its notice without unlocking send',
    (tester) async {
      final save = Completer<void>();
      final response = Completer<http.Response>();
      var requests = 0;
      await _open(
        tester,
        pendingSave: save,
        handler: (_) {
          requests++;
          return response.future;
        },
      );
      await tester.enterText(
        find.byKey(const ValueKey('feedback-message')),
        'Salvataggio lento',
      );
      await tester.pumpAndSettle();
      expect(find.text('Salvataggio della bozza…'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-send')));
      await tester.tap(find.byKey(const ValueKey('feedback-send')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(requests, 1);
      save.complete();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Salvataggio della bozza…'), findsNothing);
      expect(
        find.text('La bozza resta salvata su questo dispositivo.'),
        findsOneWidget,
      );
      expect(find.text('INVIO IN CORSO'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('feedback-send')))
            .onPressed,
        isNull,
      );
      response.complete(_ack());
      await tester.pumpAndSettle();
      expect(find.text('Grazie! Feedback inviato.'), findsOneWidget);
      expect(requests, 1);
    },
  );

  testWidgets('acknowledged delivery stays successful when local cleanup fails', (
    tester,
  ) async {
    await _open(tester, handler: (_) async => _ack(), failCleanup: true);
    await tester.enterText(
      find.byKey(const ValueKey('feedback-message')),
      'Received once',
    );
    await _tap(tester, find.byKey(const ValueKey('feedback-send')));
    expect(find.text('Grazie! Feedback inviato.'), findsOneWidget);
    expect(
      find.text(
        'Feedback ricevuto. Non siamo riusciti a cancellare la bozza su questo dispositivo.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('feedback-send')), findsNothing);
  });
}

Future<DesignFixture> _open(
  WidgetTester tester, {
  required Future<http.Response> Function(http.Request) handler,
  AppStyle style = AppStyle.southAfrica2010,
  bool failCleanup = false,
  bool failLoad = false,
  bool failSave = false,
  Completer<void>? pendingSave,
}) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fixture = DesignFixture();
  await fixture.load();
  await fixture.styleRepository.save(style);
  final transport = FormspreeFeedback(clientFactory: () => MockClient(handler));
  Future<FeedbackContext> metadata() async =>
      const FeedbackContext(version: '1', build: '2', platform: 'iOS');
  fixture.feedbackRepository = _StorageRepository(
    fixture,
    transport,
    metadata,
    failCleanup: failCleanup,
    failLoad: failLoad,
    failSave: failSave,
    pendingSave: pendingSave,
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.dispose();
  });
  await tester.pumpWidget(fixture.app);
  await tester.pumpAndSettle();
  tester
      .element(find.byType(PresentationHost))
      .read<HomeCubit>()
      .select(HomeDestination.more);
  await tester.pumpAndSettle();
  await _tap(tester, find.byKey(const ValueKey('more-feedback')));
  expect(find.byType(FeedbackScreen), findsOneWidget);
  return fixture;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _message(WidgetTester tester) => tester
    .widget<TextFormField>(find.byKey(const ValueKey('feedback-message')))
    .controller!
    .text;
http.Response _ack() => http.Response(
  '{"next":"/thanks"}',
  200,
  headers: {'content-type': 'application/json'},
);

class _StorageRepository extends FeedbackRepository {
  _StorageRepository(
    DesignFixture fixture,
    FormspreeFeedback transport,
    Future<FeedbackContext> Function() metadata, {
    this.failCleanup = false,
    this.failLoad = false,
    this.failSave = false,
    this.pendingSave,
  }) : super(fixture.database, transport: transport, contextLoader: metadata);

  final bool failCleanup;
  bool failLoad, failSave;
  final Completer<void>? pendingSave;

  @override
  Future<FeedbackDraft> loadDraft() {
    if (failLoad) return Future.error(StateError('storage unavailable'));
    return super.loadDraft();
  }

  @override
  Future<void> saveDraft(FeedbackDraft draft) async {
    if (failSave) throw StateError('storage unavailable');
    await pendingSave?.future;
    await super.saveDraft(draft);
  }

  @override
  Future<void> clearDraft() {
    if (failCleanup) return Future.error(StateError('storage unavailable'));
    return super.clearDraft();
  }
}
