import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_style.dart';
import '../models/feedback_draft.dart';

/// Native JSON transport. A request-scoped client also closes on timeout;
/// retrying is always a deliberate user action, never a transport policy.
class FormspreeFeedback {
  FormspreeFeedback({
    http.Client Function()? clientFactory,
    this.timeout = const Duration(seconds: 20),
  }) : _clientFactory = clientFactory ?? http.Client.new;

  static final endpoint = Uri.parse('https://formspree.io/f/meaerkro');
  final http.Client Function() _clientFactory;
  final Duration timeout;

  Future<void> send(
    FeedbackDraft draft,
    FeedbackContext context,
    AppStyle style,
  ) async {
    final client = _clientFactory();
    try {
      final request = http.Request('POST', endpoint)
        ..followRedirects = false
        ..headers.addAll({
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode({
          'message': draft.message.trim(),
          if (draft.email.trim().isNotEmpty) 'email': draft.email.trim(),
          'app_version': context.version,
          'app_build': context.build,
          'platform': context.platform,
          'style': style.storageValue,
        });
      final response = await (() async {
        final streamed = await client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(timeout);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          !(response.headers['content-type'] ?? '').toLowerCase().startsWith(
            'application/json',
          )) {
        throw const FeedbackDeliveryException();
      }
      final acknowledgement = jsonDecode(response.body);
      // @formspree/core 3.0.4 defines ServerSuccessResponse as {next: string}.
      // Error or challenge responses must never clear the user's draft.
      if (acknowledgement is! Map<String, dynamic> ||
          acknowledgement['next'] is! String ||
          acknowledgement.containsKey('error') ||
          acknowledgement.containsKey('errors') ||
          acknowledgement.containsKey('stripe') ||
          acknowledgement.containsKey('captcha')) {
        throw const FeedbackDeliveryException();
      }
    } finally {
      client.close();
    }
  }
}

class FeedbackDeliveryException implements Exception {
  const FeedbackDeliveryException();
}
