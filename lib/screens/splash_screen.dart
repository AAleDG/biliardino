import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/design/south_africa_artwork.dart';
import '../presentation/app_presentation.dart';

/// Bootstrap creates this route only after repositories are ready.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin, MotionAwareState {
  late final AnimationController _controller;
  bool _started = false, _leaving = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.splash)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _scheduleHome();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!reduceMotion) _controller.forward();
    }
  }

  @override
  void settleMotion() {
    _controller.stop();
    _controller.value = 1;
    _scheduleHome();
  }

  void _scheduleHome() {
    if (_leaving) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final duration = reduceMotion ? Duration.zero : AppMotion.content;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (_, _, _) => const PresentationPage(AppPage.home),
          transitionsBuilder: (context, animation, _, child) =>
              shouldReduceMotion(context)
              ? child
              : FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 132,
          child: SouthAfricaArtwork(
            mark: ArtworkMark.cornerRibbon,
            fit: BoxFit.fill,
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('NTT', style: AppType.section),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('BILIARDINO', style: AppType.event),
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, _) =>
                        FootOriginEntrance(progress: _controller.value),
                  ),
                  const SizedBox(height: 24),
                  const Text('OFFICE LEAGUE', style: AppType.utility),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Exact approved 240×180 scene: rigid mounted figure and a 32px rolling ball.
/// The ball begins beside the foot, holds 150ms, then travels 24px through 90°.
class FootOriginEntrance extends StatelessWidget {
  const FootOriginEntrance({super.key, required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) {
    final t = shouldReduceMotion(context)
        ? 1.0
        : Curves.easeOutCubic.transform(
            ((progress - .15) / .85).clamp(0.0, 1.0),
          );
    return ExcludeSemantics(
      child: SizedBox(
        width: 240,
        height: 180,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: -72,
              top: 8,
              width: 240,
              height: 160,
              child: SouthAfricaArtwork(mark: ArtworkMark.mountedFigure),
            ),
            Positioned(
              key: const ValueKey('splash-football'),
              left: 106 + 24 * t,
              top: 128,
              width: 32,
              height: 32,
              child: Transform.rotate(
                angle: (t - 1) * math.pi / 2,
                child: const SouthAfricaArtwork(mark: ArtworkMark.football),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
