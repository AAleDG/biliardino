import 'package:flutter/material.dart';

import '../theme/italia90_motion.dart';
import '../theme/italia90_tokens.dart';
import '../widgets/italia90_artwork.dart';
import '../widgets/italia90_components.dart';
import '../widgets/italia_graphic_backdrop.dart';
import '../../app_presentation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Italia90Motion.splash)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _scheduleHome();
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Italia90Motion.reducedOf(context)) {
      _controller.stop();
      _controller.value = 1;
      _scheduleHome();
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  void _scheduleHome() {
    if (_leaving) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final duration = Italia90Motion.durationOf(
        context,
        Italia90Motion.navigation,
      );
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (_, __, ___) => const PresentationPage(AppPage.home),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
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
    body: ItaliaGraphicBackdrop(
      variant: ItaliaBackdropVariant.home,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMasthead(mark: ItaliaFootball()),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _controller,
                  child: const ItaliaCiao(height: 190),
                  builder: (_, child) {
                    final value = Italia90Motion.curve.transform(
                      _controller.value,
                    );
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text('Biliardino', style: Italia90.title),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
