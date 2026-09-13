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
  });
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).height < 650;
    return FoosballScene(
      builder: (context, scene) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: compact ? 92 : 144,
                  child: Stack(
                    children: [
                      if (!compact)
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
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            icon: const Icon(Icons.arrow_back_ios_new),
                          ),
                        ),
                      Positioned(
                        top: compact ? 0 : 14,
                        left: 60,
                        right: 60,
                        child: Center(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: AppType.event.copyWith(
                                fontSize: compact ? 32 : 56,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: compact ? 90 : 129,
                    width: double.infinity,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: PassRibbons(
                            PassRibbonKind.footer,
                            scene: scene,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
