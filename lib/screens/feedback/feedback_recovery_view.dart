import 'package:flutter/material.dart';
import '../../models/app_style.dart';
import '../../presentation/italia90/theme/italia90_tokens.dart';
import '../../theme/app_theme.dart';

class FeedbackRecoveryView extends StatelessWidget {
  const FeedbackRecoveryView({
    super.key,
    required this.style,
    required this.onRestore,
    this.error,
  });
  final AppStyle style;
  final VoidCallback onRestore;
  final String? error;
  @override
  Widget build(BuildContext context) {
    final body = style == AppStyle.italia90 ? Italia90.body : AppType.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            'Il precedente invio potrebbe essere già stato ricevuto. '
            'Ripristinando la bozza e inviandola di nuovo potresti duplicare il feedback.',
            style: body,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(error!, style: body)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onRestore,
          child: const Text('Ripristina bozza'),
        ),
      ],
    );
  }
}
