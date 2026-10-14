import 'dart:async';
import 'dart:convert';

import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/models/feedback_draft.dart';
import 'package:biliardino/services/formspree_feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const context = FeedbackContext(version: '1.2.3', build: '45', platform: 'iOS');

void main() {
  test(
    'JSON submission uses only approved fields and the official acknowledgement',
    () async {
      for (final email in ['', ' person@example.com ']) {
        final client = _Client((request) async {
          expect(request.url, Uri.parse('https://formspree.io/f/meaerkro'));
          expect(request.method, 'POST');
          expect(request.followRedirects, isFalse);
          expect(request.headers['Accept'], 'application/json');
          expect(request.headers['Content-Type'], 'application/json');
          expect(jsonDecode(request.body), {
            'message': 'È un’idea ⚽',
            if (email.isNotEmpty) 'email': 'person@example.com',
            'app_version': '1.2.3',
            'app_build': '45',
            'platform': 'iOS',
            'style': 'italia-90',
          });
          return http.Response(
            '{"next":"/thanks"}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        await FormspreeFeedback(clientFactory: () => client).send(
          FeedbackDraft(message: ' È un’idea ⚽ ', email: email),
          context,
          AppStyle.italia90,
        );
        expect(client.closed, isTrue);
      }
    },
  );

  test(
    'rejections, redirects, HTML and malformed acknowledgements never succeed',
    () async {
      for (final response in [
        http.Response(
          '{"errors":[{"code":"TYPE_EMAIL","message":"Invalid email"}]}',
          422,
        ),
        http.Response('{"error":"Too many requests"}', 429),
        http.Response('{"next":"/thanks"}', 302),
        http.Response(
          '<html>Thanks</html>',
          200,
          headers: {'content-type': 'text/html'},
        ),
        http.Response('{', 200),
        http.Response('{"ok":true}', 200),
        http.Response('{"next":"/thanks","errors":[]}', 200),
        http.Response('{"next":"/challenge","captcha":true}', 200),
      ]) {
        final client = _Client(
          (_) async => http.Response(
            response.body,
            response.statusCode,
            headers: {'content-type': 'application/json', ...response.headers},
          ),
        );
        await expectLater(
          FormspreeFeedback(clientFactory: () => client).send(
            const FeedbackDraft(message: 'Hello'),
            context,
            AppStyle.southAfrica2010,
          ),
          throwsA(isA<Exception>()),
        );
        expect(client.closed, isTrue);
      }
    },
  );

  test(
    'offline and deadline failures close the request client without retry',
    () async {
      for (final offline in [true, false]) {
        var requests = 0;
        final pending = Completer<http.Response>();
        final client = _Client((_) {
          requests++;
          if (offline) throw http.ClientException('offline');
          return pending.future;
        });
        await expectLater(
          FormspreeFeedback(
            clientFactory: () => client,
            timeout: const Duration(milliseconds: 10),
          ).send(
            const FeedbackDraft(message: 'Hello'),
            context,
            AppStyle.southAfrica2010,
          ),
          throwsA(
            offline ? isA<http.ClientException>() : isA<TimeoutException>(),
          ),
        );
        expect(requests, 1);
        expect(client.closed, isTrue);
      }
    },
  );
}

class _Client extends MockClient {
  _Client(super.handler);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}
