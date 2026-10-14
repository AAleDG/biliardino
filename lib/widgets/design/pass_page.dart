import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'foosball_scene.dart';
import 'pass_artwork.dart';

/// Shared Pass composition; navigation and operations stay with the caller.
class PassPage extends StatelessWidget {
  const PassPage({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
    this.fixedFrame = false,
  });
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final bool fixedFrame;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).height < 650;
    final header = PassPageHeader(
      title: title,
      compact: compact,
      onBack: onBack,
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    return FoosballScene(
      builder: (context, scene) {
        final footer = SizedBox(
          // Keep the fixed frame small enough for the cards in short viewports.
          height: compact ? (fixedFrame ? 32 : 90) : 129,
          width: double.infinity,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: PassRibbons(PassRibbonKind.footer, scene: scene),
              ),
            ),
          ),
        );
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: fixedFrame
                ? Column(
                    children: [
                      header,
                      Expanded(child: SingleChildScrollView(child: content)),
                      footer,
                    ],
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: header),
                      SliverToBoxAdapter(child: content),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: footer,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// The established Pass header, also used over fullscreen decorative layers.
class PassPageHeader extends StatelessWidget {
  const PassPageHeader({
    super.key,
    required this.title,
    required this.compact,
    this.onBack,
    this.showArtwork = true,
    this.fitTitle = false,
    this.layoutHeight,
  });

  final String title;
  final bool compact;
  final VoidCallback? onBack;
  final bool showArtwork, fitTitle;
  final double? layoutHeight;

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text(
        title,
        style: AppType.event.copyWith(fontSize: compact ? 32 : 56),
      ),
    );
    return SizedBox(
      height: layoutHeight ?? (compact ? 92 : 144),
      child: Stack(
        children: [
          if (showArtwork && !compact)
            const Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: PassRibbons(PassRibbonKind.header),
                  ),
                ),
              ),
            ),
          if (onBack != null)
            Positioned(
              left: 8,
              top: 0,
              child: IconButton(
                onPressed: onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back_ios_new),
              ),
            ),
          Positioned(
            top: compact ? 0 : 14,
            left: 60,
            right: 60,
            child: Center(
              child: fitTitle
                  ? FittedBox(fit: BoxFit.scaleDown, child: heading)
                  : heading,
            ),
          ),
        ],
      ),
    );
  }
}
