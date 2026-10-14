import 'package:flutter/material.dart';

import '../../models/app_style.dart';
import '../../presentation/italia90/theme/italia90_tokens.dart';
import '../../theme/app_theme.dart';

class FeedbackConfirmationView extends StatelessWidget {
  const FeedbackConfirmationView({
    super.key,
    required this.style,
    required this.onReturn,
    this.notice,
  });

  final AppStyle style;
  final VoidCallback onReturn;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final body = style == AppStyle.italia90 ? Italia90.body : AppType.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            'Grazie! Feedback inviato.',
            key: const ValueKey('feedback-confirmation'),
            style: body.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 16),
          Text(notice!, style: body),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('feedback-return'),
          onPressed: onReturn,
          child: const Text('Torna ad Altro'),
        ),
      ],
    );
  }
}
