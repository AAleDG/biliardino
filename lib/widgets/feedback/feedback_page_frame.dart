import 'package:flutter/material.dart';

import '../../models/app_style.dart';
import '../../presentation/italia90/theme/italia90_tokens.dart';
import '../../presentation/italia90/widgets/italia90_components.dart';
import '../../theme/app_theme.dart';
import '../design/pass_page.dart';

/// Feedback's measured utility layout, using each presentation's existing art.
class FeedbackPageFrame extends StatelessWidget {
  const FeedbackPageFrame({
    super.key,
    required this.style,
    required this.onBack,
    required this.child,
  });

  final AppStyle style;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final italia = style == AppStyle.italia90;
    final compact =
        MediaQuery.sizeOf(context).height < 650 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final content = SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const ValueKey('feedback-scroll'),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + (compact ? 24 : 130),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (italia)
              Padding(
                padding: EdgeInsets.fromLTRB(24, compact ? 8 : 21, 56, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1,
                      child: ItaliaHomeMasthead(
                        compact: true,
                        showSubtitle: false,
                        wordmarkSize: 28,
                        markSize: 40,
                        ruleWidth: 46,
                        ruleInset: 52,
                        ruleOffsetY: -16,
                        markOffsetY: 7,
                        leading: IconButton(
                          onPressed: onBack,
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          icon: const Icon(Icons.arrow_back, size: 30),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 15),
                    Semantics(
                      header: true,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'FEEDBACK',
                            style: Italia90.display.copyWith(
                              fontSize: compact ? 36 : 48,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
                ),
              )
            else
              PassPageHeader(
                title: 'FEEDBACK',
                compact: compact,
                onBack: onBack,
                showArtwork: false,
                fitTitle: true,
                layoutHeight: compact ? 92 : 125,
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: italia ? 31 : 18),
              child: child,
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      backgroundColor: italia ? Italia90.surface : AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!compact)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.sizeOf(context).height,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Image.asset(
                    italia
                        ? 'assets/feedback/italia90-backdrop-r2.png'
                        : 'assets/feedback/south-africa-backdrop-r2.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          content,
        ],
      ),
    );
  }
}
