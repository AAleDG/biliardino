import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fieldFade;
  late final Animation<double> _ballProgress;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fieldFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.18, curve: Curves.easeIn),
    );
    _ballProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.55, curve: Curves.easeOutCubic),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.78, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.82, curve: Curves.easeOutBack),
    ));
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.80, 0.95, curve: Curves.easeOut),
    );
    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().whenComplete(_goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const _BackgroundGradient(),
              FadeTransition(
                opacity: _fieldFade,
                child: CustomPaint(
                  painter: _FieldPainter(),
                  size: Size.infinite,
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  const startMargin = -40.0;
                  final endX = width * 0.5;
                  final x =
                      startMargin + _ballProgress.value * (endX - startMargin);
                  const ballSize = 32.0;
                  const ballRadius = ballSize / 2;
                  final distance = endX - startMargin;
                  final rotation =
                      (_ballProgress.value * distance) / ballRadius;
                  final ballY = height * 0.5;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: x - ballRadius,
                        top: ballY - ballRadius,
                        width: ballSize,
                        height: ballSize,
                        child: Transform.rotate(
                          angle: rotation,
                          child: const _Ball(),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Align(
                alignment: const Alignment(0, -0.32),
                child: FadeTransition(
                  opacity: _logoFade,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: _Logo(glow: _glowPulse.value),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.72),
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: const _Tagline(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              NttColors.surfaceDark,
              NttColors.primaryDeep,
              NttColors.surfaceDark,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
      );
}

class _Ball extends StatelessWidget {
  const _Ball();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Colors.white, Color(0xFFD8DEE6)],
          stops: [0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: NttColors.accent.withOpacity(0.55),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(painter: _BallMarksPainter()),
    );
  }
}

class _BallMarksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B2D52)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(c.dx - 8, c.dy), Offset(c.dx + 8, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - 8), Offset(c.dx, c.dy + 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final fieldHalfH = math.min(size.height * 0.32, 220.0);
    final fieldHalfW = math.min(size.width * 0.45, 280.0);

    final fieldRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: fieldHalfW * 2,
      height: fieldHalfH * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect, const Radius.circular(12)),
      line,
    );

    canvas.drawLine(
      Offset(cx, cy - fieldHalfH),
      Offset(cx, cy + fieldHalfH),
      line,
    );

    canvas.drawCircle(Offset(cx, cy), 54, line);

    final goalW = fieldHalfW * 0.18;
    final goalH = fieldHalfH * 0.55;
    canvas.drawRect(
      Rect.fromLTWH(
        cx - fieldHalfW,
        cy - goalH / 2,
        goalW,
        goalH,
      ),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cx + fieldHalfW - goalW,
        cy - goalH / 2,
        goalW,
        goalH,
      ),
      line,
    );

    final rod = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final dx = fieldHalfW * (i / 4);
      canvas.drawLine(
        Offset(cx - dx, cy - fieldHalfH),
        Offset(cx - dx, cy + fieldHalfH),
        rod,
      );
      canvas.drawLine(
        Offset(cx + dx, cy - fieldHalfH),
        Offset(cx + dx, cy + fieldHalfH),
        rod,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Logo extends StatelessWidget {
  const _Logo({required this.glow});

  final double glow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NTT',
          style: TextStyle(
            color: NttColors.accent,
            fontSize: 64,
            fontWeight: FontWeight.w900,
            letterSpacing: 10,
            height: 1,
            shadows: [
              Shadow(
                color: NttColors.accent.withOpacity(glow * 0.7),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 140,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NttColors.accent.withOpacity(0),
                NttColors.accent,
                NttColors.accent.withOpacity(0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'BILIARDINO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w300,
            letterSpacing: 14,
          ),
        ),
      ],
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) => const Text(
        'OFFICE LEAGUE',
        style: TextStyle(
          color: NttColors.textFaint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 6,
        ),
      );
}
