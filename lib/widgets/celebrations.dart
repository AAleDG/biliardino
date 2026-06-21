import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class Celebrations {
  Celebrations._();

  static void showGoal(
    BuildContext context, {
    required Color color,
    required String teamLabel,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GoalOverlay(
        color: color,
        teamLabel: teamLabel,
        onComplete: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    HapticFeedback.mediumImpact();
  }

  static void showVictory(
    BuildContext context, {
    required Color color,
    required String teamLabel,
    required List<String> playerNames,
    required int winnerScore,
    required int loserScore,
    required VoidCallback onContinue,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _VictoryOverlay(
        color: color,
        teamLabel: teamLabel,
        playerNames: playerNames,
        winnerScore: winnerScore,
        loserScore: loserScore,
        onContinue: () {
          if (entry.mounted) entry.remove();
          onContinue();
        },
      ),
    );
    overlay.insert(entry);
    HapticFeedback.heavyImpact();
  }
}

class _GoalOverlay extends StatefulWidget {
  const _GoalOverlay({
    required this.color,
    required this.teamLabel,
    required this.onComplete,
  });

  final Color color;
  final String teamLabel;
  final VoidCallback onComplete;

  @override
  State<_GoalOverlay> createState() => _GoalOverlayState();
}

class _GoalOverlayState extends State<_GoalOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _tint;
  late final Animation<double> _flash;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_ctrl);

    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_ctrl);

    _tint = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.45), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 0.45, end: 0.0), weight: 88),
    ]).animate(_ctrl);

    _flash = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 6),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 14),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 80),
    ]).animate(_ctrl);

    _ctrl.forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      widget.color.withOpacity(_tint.value),
                      widget.color.withOpacity(_tint.value * 0.2),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_flash.value),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: Opacity(
                      opacity: _fade.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: SizedBox(
                          width: constraints.maxWidth - 40,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'GOAL!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 108,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 8,
                                    height: 1,
                                    shadows: [
                                      Shadow(
                                          color: widget.color,
                                          blurRadius: 28),
                                      Shadow(
                                        color: widget.color.withOpacity(0.7),
                                        blurRadius: 60,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: widget.color,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.color.withOpacity(0.6),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  widget.teamLabel,
                                  style: const TextStyle(
                                    color: NttColors.surfaceDark,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VictoryOverlay extends StatefulWidget {
  const _VictoryOverlay({
    required this.color,
    required this.teamLabel,
    required this.playerNames,
    required this.winnerScore,
    required this.loserScore,
    required this.onContinue,
  });

  final Color color;
  final String teamLabel;
  final List<String> playerNames;
  final int winnerScore;
  final int loserScore;
  final VoidCallback onContinue;

  @override
  State<_VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<_VictoryOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _confetti;
  late final List<_ConfettiSpec> _specs;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..forward();
    final rng = math.Random();
    _specs =
        List.generate(90, (_) => _ConfettiSpec.random(rng, widget.color));
  }

  Animation<double> _interval(double begin, double end,
      [Curve curve = Curves.easeOutBack]) {
    return CurvedAnimation(
      parent: _entry,
      curve: Interval(begin, end, curve: curve),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trophyAnim = _interval(0.0, 0.40);
    final titleAnim = _interval(0.18, 0.50);
    final teamAnim = _interval(0.38, 0.68);
    final scoreAnim = _interval(0.55, 0.82);
    final buttonAnim = _interval(0.78, 1.0, Curves.easeOut);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.3,
                colors: [
                  widget.color.withOpacity(0.30),
                  NttColors.surfaceDark.withOpacity(0.97),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _confetti,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(
                specs: _specs,
                t: _confetti.value * 6,
              ),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - 48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    _staggered(
                      trophyAnim,
                      scale: true,
                      child: Icon(
                        Icons.emoji_events,
                        size: 116,
                        color: widget.color,
                        shadows: [
                          Shadow(color: widget.color, blurRadius: 36),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _staggered(
                      titleAnim,
                      slideUp: true,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'VITTORIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _staggered(
                      teamAnim,
                      slideUp: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.55),
                              blurRadius: 26,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.teamLabel,
                          style: const TextStyle(
                            color: NttColors.surfaceDark,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _staggered(
                      teamAnim,
                      child: Text(
                        widget.playerNames.join('  &  '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _staggered(
                      scoreAnim,
                      scale: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${widget.winnerScore} — ${widget.loserScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _staggered(
                      buttonAnim,
                      slideUp: true,
                      child: SizedBox(
                        width: 220,
                        child: ElevatedButton(
                          onPressed: widget.onContinue,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                            ),
                          ),
                          child: const Text('CONTINUA'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staggered(
    Animation<double> anim, {
    bool slideUp = false,
    bool scale = false,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) {
        final v = anim.value.clamp(0.0, 1.0);
        Widget out = Opacity(opacity: v, child: c);
        if (slideUp) {
          out = Transform.translate(
            offset: Offset(0, 28 * (1 - v)),
            child: out,
          );
        }
        if (scale) {
          out = Transform.scale(scale: 0.6 + 0.4 * v, child: out);
        }
        return out;
      },
      child: child,
    );
  }
}

class _ConfettiSpec {
  _ConfettiSpec({
    required this.startXNorm,
    required this.startYOffset,
    required this.velocity,
    required this.rotationSpeed,
    required this.initialRotation,
    required this.color,
    required this.size,
    required this.isRect,
    required this.startDelay,
  });

  final double startXNorm;
  final double startYOffset;
  final Offset velocity;
  final double rotationSpeed;
  final double initialRotation;
  final Color color;
  final double size;
  final bool isRect;
  final double startDelay;

  factory _ConfettiSpec.random(math.Random rng, Color teamColor) {
    const palette = [
      NttColors.accent,
      NttColors.success,
      NttColors.warning,
      Colors.white,
    ];
    final colors = <Color>[teamColor, teamColor, ...palette, Colors.white];
    return _ConfettiSpec(
      startXNorm: rng.nextDouble(),
      startYOffset: -30 - rng.nextDouble() * 160,
      velocity: Offset(
        (rng.nextDouble() - 0.5) * 220,
        160 + rng.nextDouble() * 220,
      ),
      rotationSpeed: (rng.nextDouble() - 0.5) * 10,
      initialRotation: rng.nextDouble() * math.pi * 2,
      color: colors[rng.nextInt(colors.length)],
      size: 5 + rng.nextDouble() * 9,
      isRect: rng.nextBool(),
      startDelay: rng.nextDouble() * 1.2,
    );
  }

  Offset positionAt(double t, Size canvasSize) {
    final effT = math.max(0.0, t - startDelay);
    final dx = startXNorm * canvasSize.width + velocity.dx * effT;
    final dy =
        startYOffset + velocity.dy * effT + 420 * effT * effT * 0.5;
    return Offset(dx, dy);
  }

  double rotationAt(double t) {
    final effT = math.max(0.0, t - startDelay);
    return initialRotation + rotationSpeed * effT;
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.specs, required this.t});

  final List<_ConfettiSpec> specs;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in specs) {
      final pos = s.positionAt(t, size);
      if (pos.dy > size.height + 40 || pos.dy < -60) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(s.rotationAt(t));
      paint.color = s.color;
      if (s.isRect) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: s.size,
            height: s.size * 0.55,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, s.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
