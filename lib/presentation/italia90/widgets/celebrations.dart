import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/italia90_motion.dart';
import '../theme/italia90_tokens.dart';

class Celebrations {
  Celebrations._();
  static final _goals = Expando<CelebrationOverlayHandle>();
  static final _matchDecorations = Expando<CelebrationOverlayHandle>();

  static CelebrationOverlayHandle showMatchStart(BuildContext context) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _goals[overlay]?.dismiss();
    _matchDecorations[overlay]?.dismiss();
    late CelebrationOverlayHandle handle;
    final entry = OverlayEntry(builder: (_) => const _MatchStartOverlay());
    handle = CelebrationOverlayHandle._(entry, () {
      if (identical(_matchDecorations[overlay], handle)) {
        _matchDecorations[overlay] = null;
      }
    });
    _matchDecorations[overlay] = handle;
    overlay.insert(entry);
    return handle;
  }

  static CelebrationOverlayHandle showGoal(
    BuildContext context, {
    required Color color,
    required String teamLabel,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _goals[overlay]?.dismiss();
    _matchDecorations[overlay]?.dismiss();
    late CelebrationOverlayHandle handle;
    final entry = OverlayEntry(
      builder: (_) => _GoalOverlay(
        color: color,
        teamLabel: teamLabel,
        onComplete: () => handle.dismiss(),
      ),
    );
    handle = CelebrationOverlayHandle._(entry, () {
      if (identical(_goals[overlay], handle)) _goals[overlay] = null;
    });
    _goals[overlay] = handle;
    overlay.insert(entry);
    HapticFeedback.mediumImpact();
    return handle;
  }

  static CelebrationOverlayHandle showVictory(
    BuildContext context, {
    required Color color,
    required String teamLabel,
    required List<String> playerNames,
    required int winnerScore,
    required int loserScore,
    required VoidCallback onChangeTeams,
    required VoidCallback onRematch,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _goals[overlay]?.dismiss();
    _matchDecorations[overlay]?.dismiss();
    late CelebrationOverlayHandle handle;
    final entry = OverlayEntry(
      builder: (_) => _VictoryOverlay(
        color: color,
        teamLabel: teamLabel,
        playerNames: playerNames,
        winnerScore: winnerScore,
        loserScore: loserScore,
        onChangeTeams: () {
          handle.dismiss();
          onChangeTeams();
        },
        onRematch: () {
          handle.dismiss();
          onRematch();
        },
      ),
    );
    handle = CelebrationOverlayHandle._(entry);
    overlay.insert(entry);
    HapticFeedback.heavyImpact();
    return handle;
  }
}

class CelebrationOverlayHandle {
  CelebrationOverlayHandle._(this._entry, [this._onDismiss]);
  OverlayEntry? _entry;
  final VoidCallback? _onDismiss;

  void dismiss() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry.remove();
    entry.dispose();
    _onDismiss?.call();
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
  late final AnimationController _controller;
  late final Timer _expiry;
  bool? _reduced;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Italia90Motion.goal,
    );
    // Feedback lifetime is independent of motion; reduced motion still has a readable hold.
    _expiry = Timer(Italia90Motion.goal, widget.onComplete);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = Italia90Motion.reducedOf(context);
    if (_reduced == reduced) return;
    _reduced = reduced;
    if (reduced) {
      _controller.stop();
      _controller.value = .5;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _expiry.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('goal-overlay'),
    container: true,
    liveRegion: true,
    label: 'Goal. ${widget.teamLabel}',
    child: IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                final t = _controller.value;
                final opacity = _reduced == true
                    ? 1.0
                    : t < .18
                    ? t / .18
                    : t > .75
                    ? (1 - t) / .25
                    : 1.0;
                return Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      _reduced == true
                          ? 0
                          : 8 *
                                (1 -
                                    Curves.easeOut.transform(
                                      (t / .18).clamp(0.0, 1.0),
                                    )),
                    ),
                    child: child,
                  ),
                );
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Italia90.surface,
                    borderRadius: BorderRadius.circular(Italia90.panelRadius),
                    border: Border.all(color: widget.color, width: 3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GOAL!',
                          style: Italia90.display.copyWith(fontSize: 56),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.teamLabel,
                          textAlign: TextAlign.center,
                          style: Italia90.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MatchStartOverlay extends StatefulWidget {
  const _MatchStartOverlay();

  @override
  State<_MatchStartOverlay> createState() => _MatchStartOverlayState();
}

class _MatchStartOverlayState extends State<_MatchStartOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _reduced;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Italia90Motion.matchWave,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = Italia90Motion.reducedOf(context);
    if (_reduced == reduced) return;
    final firstVisit = _reduced == null;
    _reduced = reduced;
    if (reduced) {
      _controller.stop();
      _controller.value = 1;
    } else if (firstVisit) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            if (_reduced == true || _controller.isCompleted) {
              return const SizedBox.shrink();
            }
            return KeyedSubtree(
              key: const ValueKey('match-decoration'),
              child: KeyedSubtree(
                key: const ValueKey('match-wave'),
                child: CustomPaint(
                  painter: _MatchDecorationPainter(
                    waveProgress: _controller.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _MatchDecorationPainter extends CustomPainter {
  _MatchDecorationPainter({required this.waveProgress});

  final double waveProgress;

  static const _palette = <Color>[
    Italia90.teamOne,
    Italia90.green,
    Italia90.red,
    Italia90.teamTwo,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 0) return;

    if (waveProgress < 1) {
      _paintWave(canvas, size, waveProgress);
    }
  }

  void _paintWave(Canvas canvas, Size size, double progress) {
    final eased = Curves.easeOutCubic.transform(progress);
    final center = Offset(size.width / 2, size.height * .46);
    final baseRadius = math.min(size.shortestSide * .12, 56.0);
    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.square;
    for (var index = 0; index < 4; index++) {
      rings.color = _palette[index].withValues(
        alpha: .12 + ((1 - eased) * .28) - (index * .02),
      );
      final radius = baseRadius + (index * 18) + (eased * 150);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + (index * math.pi / 2),
        math.pi * .48,
        false,
        rings,
      );
    }

    final rays = Paint()..style = PaintingStyle.fill;
    final innerRadius = baseRadius + (eased * 18);
    final outerRadius = baseRadius + 30 + (eased * 130);
    for (var index = 0; index < 12; index++) {
      final angle = index * math.pi * 2 / 12;
      final width = index.isEven ? .07 : .045;
      final path = Path()
        ..moveTo(
          center.dx + math.cos(angle - width) * innerRadius,
          center.dy + math.sin(angle - width) * innerRadius,
        )
        ..lineTo(
          center.dx + math.cos(angle - width * .5) * outerRadius,
          center.dy + math.sin(angle - width * .5) * outerRadius,
        )
        ..lineTo(
          center.dx + math.cos(angle + width * .5) * outerRadius,
          center.dy + math.sin(angle + width * .5) * outerRadius,
        )
        ..lineTo(
          center.dx + math.cos(angle + width) * innerRadius,
          center.dy + math.sin(angle + width) * innerRadius,
        )
        ..close();
      rays.color = _palette[index % _palette.length].withValues(
        alpha: .05 + ((1 - eased) * .22),
      );
      canvas.drawPath(path, rays);
    }
  }

  @override
  bool shouldRepaint(covariant _MatchDecorationPainter oldDelegate) =>
      oldDelegate.waveProgress != waveProgress;
}

class _VictoryOverlay extends StatefulWidget {
  const _VictoryOverlay({
    required this.color,
    required this.teamLabel,
    required this.playerNames,
    required this.winnerScore,
    required this.loserScore,
    required this.onChangeTeams,
    required this.onRematch,
  });
  final Color color;
  final String teamLabel;
  final List<String> playerNames;
  final int winnerScore;
  final int loserScore;
  final VoidCallback onChangeTeams;
  final VoidCallback onRematch;
  @override
  State<_VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<_VictoryOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _confetti;
  late final List<_ConfettiSpec> _specs;
  bool? _reduced;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: Italia90Motion.victory,
    );
    _confetti = AnimationController(
      vsync: this,
      duration: Italia90Motion.victoryCelebration,
    );
    final rng = math.Random(90);
    _specs = List.generate(32, (_) => _ConfettiSpec.random(rng));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = Italia90Motion.reducedOf(context);
    if (_reduced == reduced) return;
    final firstVisit = _reduced == null;
    _reduced = reduced;
    if (reduced) {
      _entrance.stop();
      _entrance.value = 1;
      _confetti.stop();
      _confetti.value = 1;
    } else if (firstVisit) {
      _entrance.forward();
      _confetti.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlockSemantics(
    child: Semantics(
      key: const ValueKey('victory-overlay'),
      container: true,
      liveRegion: true,
      namesRoute: true,
      scopesRoute: true,
      explicitChildNodes: true,
      label:
          'Vittoria: ${widget.teamLabel}. ${widget.playerNames.join(' e ')}. Punteggio ${widget.winnerScore} a ${widget.loserScore}.',
      child: Material(
        type: MaterialType.transparency,
        child: FocusScope(
          autofocus: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ModalBarrier(
                color: Italia90.scrim,
                dismissible: false,
                barrierSemanticsDismissible: false,
              ),
              Positioned.fill(
                child: KeyedSubtree(
                  key: const ValueKey('victory-effects'),
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _confetti,
                        builder: (_, __) {
                          if (_confetti.isCompleted) {
                            return const SizedBox.shrink();
                          }
                          return CustomPaint(
                            painter: _VictoryEffectsPainter(
                              t: _confetti.value,
                              accent: widget.color,
                            ),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AnimatedBuilder(
                        animation: _entrance,
                        builder: (_, child) {
                          final progress = Italia90Motion.curve.transform(
                            _entrance.value,
                          );
                          return Transform.translate(
                            offset: Offset(0, 10 * (1 - progress)),
                            child: Transform.rotate(
                              angle: -0.035 * (1 - progress),
                              child: Transform.scale(
                                scale: .94 + (.06 * progress),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: const ValueKey('victory-winner-card'),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Italia90.surface,
                              borderRadius: BorderRadius.circular(
                                Italia90.sheetRadius,
                              ),
                              border: Border.all(
                                color: Italia90.primary,
                                width: 3,
                              ),
                              boxShadow: [
                                ...Italia90.rosterShadow,
                                BoxShadow(
                                  color: Italia90.primary.withValues(alpha: .2),
                                  blurRadius: 22,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                20,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AnimatedBuilder(
                                    animation: _confetti,
                                    builder: (_, child) {
                                      final progress = _reduced == true
                                          ? 1.0
                                          : _sealProgress(_confetti.value);
                                      return Opacity(
                                        opacity: progress,
                                        child: Transform.scale(
                                          scale: .78 + (.22 * progress),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: ExcludeSemantics(
                                      child: SizedBox(
                                        key: const ValueKey('victory-seal'),
                                        height: 250,
                                        width: double.infinity,
                                        child: AnimatedBuilder(
                                          animation: _confetti,
                                          builder: (_, child) {
                                            final progress = _reduced == true
                                                ? 1.0
                                                : _confetti.value;
                                            final swing = _reduced == true
                                                ? 0.0
                                                : math.sin(
                                                        progress * math.pi * 4,
                                                      ) *
                                                      .045 *
                                                      (1 - progress);
                                            final pulse = progress < .38
                                                ? math.sin(
                                                        progress /
                                                            .38 *
                                                            math.pi,
                                                      ) *
                                                      .05
                                                : 0.0;
                                            return Transform.rotate(
                                              angle: swing,
                                              child: Transform.scale(
                                                scale: 1 + pulse,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: KeyedSubtree(
                                            key: const ValueKey(
                                              'victory-trophy',
                                            ),
                                            child: CustomPaint(
                                              painter: _VictoryShieldPainter(
                                                accent: widget.color,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'VITTORIA',
                                      textAlign: TextAlign.center,
                                      style: Italia90.display.copyWith(
                                        fontSize: 52,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.teamLabel,
                                    textAlign: TextAlign.center,
                                    style: Italia90.title.copyWith(
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.playerNames.join('  &  '),
                                    textAlign: TextAlign.center,
                                    style: Italia90.body.copyWith(fontSize: 18),
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedBuilder(
                                    animation: _confetti,
                                    builder: (_, child) {
                                      final progress = _confetti.value;
                                      final pulse = progress < .42
                                          ? math.sin(progress / .42 * math.pi) *
                                                .06
                                          : 0.0;
                                      return Transform.scale(
                                        scale: 1 + pulse,
                                        child: child,
                                      );
                                    },
                                    child: FittedBox(
                                      key: const ValueKey('victory-score'),
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${widget.winnerScore} — ${widget.loserScore}',
                                        style: Italia90.score.copyWith(
                                          color: Italia90.ink,
                                          fontSize: 78,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  FilledButton(
                                    onPressed: widget.onRematch,
                                    child: const Text('RIVINCITA'),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: widget.onChangeTeams,
                                    child: const Text('CAMBIA SQUADRA'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_reduced != true)
                Positioned.fill(
                  child: KeyedSubtree(
                    key: const ValueKey('victory-fireworks'),
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _confetti,
                          builder: (_, __) {
                            if (_confetti.isCompleted) {
                              return const SizedBox.shrink();
                            }
                            return CustomPaint(
                              painter: _VictoryFireworksPainter(
                                t: _confetti.value,
                                accent: widget.color,
                              ),
                              child: const SizedBox.expand(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              if (_reduced != true)
                Positioned.fill(
                  child: KeyedSubtree(
                    key: const ValueKey('victory-confetti'),
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _confetti,
                          builder: (_, __) {
                            if (_confetti.isCompleted) {
                              return const SizedBox.shrink();
                            }
                            return CustomPaint(
                              painter: _ConfettiPainter(
                                specs: _specs,
                                t: _confetti.value,
                              ),
                              child: const SizedBox.expand(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

double _sealProgress(double value) {
  final normalized = ((value - .58) / .3).clamp(0.0, 1.0);
  return Curves.easeOutCubic.transform(normalized);
}

class _VictoryShieldPainter extends CustomPainter {
  _VictoryShieldPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 0) return;

    final scale = math.min(size.height / 205, size.width / 230);
    canvas.save();
    _paintBackdrop(canvas, size);
    canvas.translate(size.width / 2, size.height * .55);
    canvas.scale(scale);
    _paintStars(canvas);
    _paintShield(canvas);
    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final red = Paint()..color = Italia90.primary;
    final blue = Paint()..color = Italia90.teamOne;
    final yellow = Paint()..color = Italia90.teamTwo;
    final green = Paint()..color = Italia90.green;
    final white = Paint()..color = Italia90.surface;

    _drawMirroredPolygon(canvas, size, red, const [
      Offset(.00, .04),
      Offset(.30, .04),
      Offset(.25, .28),
      Offset(.00, .18),
    ]);
    _drawMirroredPolygon(canvas, size, white, const [
      Offset(.00, .18),
      Offset(.35, .48),
      Offset(.29, .40),
      Offset(.00, .28),
    ]);
    _drawMirroredPolygon(canvas, size, blue, const [
      Offset(.00, .32),
      Offset(.38, .66),
      Offset(.30, .56),
      Offset(.00, .44),
    ]);
    _drawMirroredPolygon(canvas, size, yellow, const [
      Offset(.00, .55),
      Offset(.31, .80),
      Offset(.24, .70),
      Offset(.00, .64),
    ]);
    _drawMirroredPolygon(canvas, size, red, const [
      Offset(.05, .80),
      Offset(.22, .84),
      Offset(.15, .93),
      Offset(.04, .89),
    ]);
    _drawMirroredPolygon(canvas, size, green, const [
      Offset(.08, .90),
      Offset(.18, .92),
      Offset(.14, .98),
      Offset(.07, .95),
    ]);
  }

  void _drawMirroredPolygon(
    Canvas canvas,
    Size size,
    Paint paint,
    List<Offset> normalizedPoints,
  ) {
    final points = normalizedPoints
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList();
    _drawPolygon(canvas, paint, points);
    _drawPolygon(
      canvas,
      paint,
      points.map((point) => Offset(size.width - point.dx, point.dy)).toList(),
    );
  }

  void _paintStars(Canvas canvas) {
    _drawStar(canvas, const Offset(0, -94), 18, 8, Italia90.teamTwo);
    _drawStar(canvas, const Offset(-35, -87), 10, 4, Italia90.ink);
    _drawStar(canvas, const Offset(35, -87), 10, 4, Italia90.ink);
  }

  void _paintShield(Canvas canvas) {
    final outerPath = _shieldPath(0);
    final borderPath = _shieldPath(6);
    final innerPath = _shieldPath(11);

    canvas.drawPath(outerPath, Paint()..color = Italia90.ink);
    canvas.drawPath(borderPath, Paint()..color = Italia90.surface);
    canvas.drawPath(innerPath, Paint()..color = Italia90.primary);

    canvas.save();
    canvas.clipPath(innerPath);
    final panelPaint = Paint()..color = Italia90.red;
    canvas.drawRect(const Rect.fromLTRB(-48, -61, -25, 43), panelPaint);
    panelPaint.color = Italia90.green;
    canvas.drawRect(const Rect.fromLTRB(-48, -61, -41, -12), panelPaint);
    panelPaint.color = Italia90.red;
    canvas.drawRect(const Rect.fromLTRB(25, -61, 48, 43), panelPaint);
    canvas.restore();

    _paintInnerLightning(canvas);
    _paintFoosballPlayer(canvas);
    _paintFootball(canvas, const Offset(0, 52), 21);
  }

  Path _shieldPath(double inset) => Path()
    ..moveTo(-57 + inset, -55 + inset)
    ..lineTo(-28, -71 + inset)
    ..lineTo(0, -78 + inset)
    ..lineTo(28, -71 + inset)
    ..lineTo(57 - inset, -55 + inset)
    ..lineTo(54 - inset, 17 - inset)
    ..quadraticBezierTo(42, 52 - inset, 0, 77 - inset)
    ..quadraticBezierTo(-42, 52 - inset, -54 + inset, 17 - inset)
    ..close();

  void _paintInnerLightning(Canvas canvas) {
    final yellow = Paint()..color = Italia90.teamTwo;
    final blue = Paint()..color = Italia90.teamOne;
    _drawPolygon(canvas, yellow, const [
      Offset(-45, -5),
      Offset(-22, 3),
      Offset(-34, 14),
      Offset(-16, 13),
      Offset(-39, 37),
      Offset(-31, 16),
      Offset(-48, 20),
    ]);
    _drawPolygon(canvas, yellow, const [
      Offset(45, -5),
      Offset(22, 3),
      Offset(34, 14),
      Offset(16, 13),
      Offset(39, 37),
      Offset(31, 16),
      Offset(48, 20),
    ]);
    _drawPolygon(canvas, blue, const [
      Offset(-82, -8),
      Offset(-53, 4),
      Offset(-65, 12),
      Offset(-91, 0),
    ]);
    _drawPolygon(canvas, blue, const [
      Offset(82, -8),
      Offset(53, 4),
      Offset(65, 12),
      Offset(91, 0),
    ]);
  }

  void _paintFoosballPlayer(Canvas canvas) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..color = Italia90.surface;
    final fill = Paint()..color = Italia90.ink;

    canvas.drawCircle(const Offset(0, -42), 11, outline);
    canvas.drawCircle(const Offset(0, -42), 8, fill);
    final body = Path()
      ..moveTo(-12, -30)
      ..lineTo(12, -30)
      ..lineTo(10, 2)
      ..lineTo(4, 12)
      ..lineTo(-4, 12)
      ..lineTo(-10, 2)
      ..close();
    canvas.drawPath(body, outline);
    canvas.drawPath(body, fill);
    canvas.drawLine(const Offset(-48, -3), const Offset(48, -3), outline);
    canvas.drawLine(
      const Offset(-48, -3),
      const Offset(48, -3),
      Paint()
        ..color = Italia90.ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.square,
    );
    canvas.drawRect(const Rect.fromLTRB(-7, 11, 7, 30), outline);
    canvas.drawRect(const Rect.fromLTRB(-5, 11, 5, 28), fill);
  }

  void _paintFootball(Canvas canvas, Offset center, double radius) {
    final ball = Paint()..color = Colors.white;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Italia90.ink;
    canvas.drawCircle(center, radius, ball);
    canvas.drawCircle(center, radius, outline);
    final patches = Paint()..color = Italia90.ink;
    for (var index = 0; index < 5; index++) {
      final angle = index * math.pi * 2 / 5 - math.pi / 2;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * radius * .48,
          center.dy + math.sin(angle) * radius * .48,
        ),
        radius * .18,
        patches,
      );
    }
    canvas.drawCircle(center, radius * .18, patches);
  }

  void _drawPolygon(Canvas canvas, Paint paint, List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    Color color,
  ) {
    final path = Path();
    for (var index = 0; index < 10; index++) {
      final radius = index.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + index * math.pi / 5;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _VictoryShieldPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

void _paintFoosball(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required double alpha,
  required double rotation,
}) {
  final fill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white.withValues(alpha: alpha);
  canvas.drawCircle(center, radius, fill);

  final outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Italia90.ink.withValues(alpha: alpha);
  canvas.drawCircle(center, radius, outline);

  final patches = Paint()
    ..style = PaintingStyle.fill
    ..color = Italia90.ink.withValues(alpha: alpha);
  for (var index = 0; index < 5; index++) {
    final angle = rotation + index * math.pi * 2 / 5;
    final patchCenter = Offset(
      center.dx + math.cos(angle) * radius * .43,
      center.dy + math.sin(angle) * radius * .43,
    );
    canvas.drawCircle(patchCenter, radius * .16, patches);
  }
  canvas.drawCircle(center, radius * .16, patches);
}

class _VictoryEffectsPainter extends CustomPainter {
  _VictoryEffectsPainter({required this.t, required this.accent});

  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 0 || t >= 1) return;

    final rawProgress = t.clamp(0.0, 1.0);
    final shockwaveProgress = Curves.easeOutCubic.transform(
      (rawProgress / .46).clamp(0.0, 1.0),
    );
    final orbitProgress = Curves.easeInOut.transform(
      ((rawProgress - .08) / .84).clamp(0.0, 1.0),
    );
    final center = Offset(size.width / 2, size.height * .42);
    final radius = math.min(size.shortestSide * .23, 112.0);
    final palette = <Color>[
      Italia90.teamOne,
      Italia90.green,
      Italia90.red,
      Italia90.teamTwo,
      accent,
    ];

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rawProgress * math.pi * .06);
    _paintShockwave(
      canvas,
      radius: radius,
      progress: shockwaveProgress,
      palette: palette,
    );
    _paintOrbit(
      canvas,
      radius: radius,
      progress: orbitProgress,
      palette: palette,
    );

    canvas.restore();
  }

  void _paintShockwave(
    Canvas canvas, {
    required double radius,
    required double progress,
    required List<Color> palette,
  }) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 5;
    for (var index = 0; index < 4; index++) {
      final ringRadius =
          radius * (.72 + (index * .16) + (progress * (.9 + index * .12)));
      ringPaint.color = palette[index].withValues(
        alpha: .16 + ((1 - progress) * .42) - (index * .02),
      );
      final start = (index * math.pi / 2) + (progress * math.pi * .3);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ringRadius),
        start,
        math.pi * .46,
        false,
        ringPaint,
      );
    }

    final rayPaint = Paint()..style = PaintingStyle.fill;
    final innerRadius = radius * (.72 + (progress * .2));
    final outerRadius = radius * (1.4 + (progress * .75));
    for (var index = 0; index < 12; index++) {
      final angle = index * math.pi * 2 / 12 + (progress * math.pi * .18);
      final width = index.isEven ? .075 : .045;
      final outer = outerRadius + ((index % 3) * 12);
      final path = Path()
        ..moveTo(
          _point(innerRadius, angle - width).dx,
          _point(innerRadius, angle - width).dy,
        )
        ..lineTo(
          _point(outer, angle - (width * .55)).dx,
          _point(outer, angle - (width * .55)).dy,
        )
        ..lineTo(
          _point(outer, angle + (width * .55)).dx,
          _point(outer, angle + (width * .55)).dy,
        )
        ..lineTo(
          _point(innerRadius, angle + width).dx,
          _point(innerRadius, angle + width).dy,
        )
        ..close();
      rayPaint.color = palette[index % palette.length].withValues(
        alpha: .08 + ((1 - progress) * .34),
      );
      canvas.drawPath(path, rayPaint);
    }
  }

  void _paintOrbit(
    Canvas canvas, {
    required double radius,
    required double progress,
    required List<Color> palette,
  }) {
    final orbitRadius = radius * 1.48;
    final orbitRect = Rect.fromCircle(center: Offset.zero, radius: orbitRadius);
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    final orbitOpacity = .18 + (progress * .34);
    for (var index = 0; index < 12; index++) {
      orbitPaint.color = palette[index % palette.length].withValues(
        alpha: orbitOpacity,
      );
      canvas.drawArc(
        orbitRect,
        -math.pi / 2 + (index * math.pi / 6) + (progress * math.pi * 2.2),
        math.pi / 6 * .62,
        false,
        orbitPaint,
      );
    }

    final orbitAngle = -math.pi / 2 + (progress * math.pi * 2.4);
    for (var index = 2; index >= 0; index--) {
      final trailProgress = (progress - (index * .1)).clamp(0.0, 1.0);
      if (trailProgress <= 0) continue;
      _paintBall(
        canvas,
        center: _point(
          orbitRadius,
          -math.pi / 2 + (trailProgress * math.pi * 2.4),
        ),
        radius: 11 - (index * 1.5),
        alpha: .22 + ((2 - index) * .18),
        rotation: orbitAngle + (index * .2),
      );
    }
  }

  void _paintBall(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double alpha,
    required double rotation,
  }) => _paintFoosball(
    canvas,
    center: center,
    radius: radius,
    alpha: alpha,
    rotation: rotation,
  );

  Offset _point(double radius, double angle) =>
      Offset(math.cos(angle) * radius, math.sin(angle) * radius);

  @override
  bool shouldRepaint(covariant _VictoryEffectsPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.accent != accent;
}

class _VictoryFireworksPainter extends CustomPainter {
  _VictoryFireworksPainter({required this.t, required this.accent});

  final double t;
  final Color accent;

  static const _burstDuration = .22;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 0 || t >= 1) return;

    final progress = t.clamp(0.0, 1.0).toDouble();
    final palette = <Color>[
      Italia90.teamOne,
      Italia90.teamTwo,
      Italia90.red,
      Italia90.green,
      accent,
      Italia90.ink,
    ];

    _paintBurst(
      canvas,
      center: Offset(size.width * .12, size.height * .27),
      progress: progress,
      start: .03,
      palette: palette,
      paletteOffset: 0,
      rotation: -.08,
    );
    _paintBurst(
      canvas,
      center: Offset(size.width * .88, size.height * .33),
      progress: progress,
      start: .16,
      palette: palette,
      paletteOffset: 2,
      rotation: .12,
    );
    _paintBurst(
      canvas,
      center: Offset(size.width * .10, size.height * .38),
      progress: progress,
      start: .28,
      palette: palette,
      paletteOffset: 3,
      rotation: .05,
    );
    _paintBurst(
      canvas,
      center: Offset(size.width * .90, size.height * .27),
      progress: progress,
      start: .40,
      palette: palette,
      paletteOffset: 1,
      rotation: -.12,
    );
    _paintBurst(
      canvas,
      center: Offset(size.width * .12, size.height * .31),
      progress: progress,
      start: .53,
      palette: palette,
      paletteOffset: 4,
      rotation: -.02,
    );
    _paintBurst(
      canvas,
      center: Offset(size.width * .88, size.height * .37),
      progress: progress,
      start: .65,
      palette: palette,
      paletteOffset: 0,
      rotation: .08,
    );
    _paintBurst(
      canvas,
      center: Offset(size.width * .11, size.height * .24),
      progress: progress,
      start: .77,
      palette: palette,
      paletteOffset: 2,
      rotation: .14,
    );
    _paintBurst(
      canvas,
      center: Offset(size.width * .89, size.height * .30),
      progress: progress,
      start: .89,
      palette: palette,
      paletteOffset: 3,
      rotation: -.06,
    );
  }

  void _paintBurst(
    Canvas canvas, {
    required Offset center,
    required double progress,
    required double start,
    required List<Color> palette,
    required int paletteOffset,
    required double rotation,
  }) {
    final elapsed = progress - start;
    if (elapsed < 0 || elapsed > _burstDuration) return;

    final local = (elapsed / _burstDuration).clamp(0.0, 1.0).toDouble();
    final eased = Curves.easeOutCubic.transform(local);
    final fade = (1 - Curves.easeIn.transform(local))
        .clamp(0.0, 1.0)
        .toDouble();
    final innerRadius = 4 + (eased * 8);
    final outerRadius = 12 + (eased * 44);
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final sparkPaint = Paint()..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      4 + (eased * 2),
      Paint()
        ..style = PaintingStyle.fill
        ..color = Italia90.surface.withValues(alpha: fade * .86),
    );

    for (var index = 0; index < 14; index++) {
      final angle = rotation + (index * math.pi * 2 / 14);
      final length = outerRadius * (index.isEven ? 1.0 : .76);
      final from = Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * innerRadius,
      );
      final to = Offset(
        center.dx + math.cos(angle) * length,
        center.dy + math.sin(angle) * length,
      );
      rayPaint
        ..strokeWidth = index.isEven ? 3 : 2
        ..color = palette[(index + paletteOffset) % palette.length].withValues(
          alpha: fade * (index.isEven ? .82 : .62),
        );
      canvas.drawLine(from, to, rayPaint);

      if (index.isEven) {
        sparkPaint.color = rayPaint.color;
        canvas.drawCircle(to, 2.2, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VictoryFireworksPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.accent != accent;
}

class _ConfettiSpec {
  _ConfettiSpec({
    required this.startXNorm,
    required this.startYOffset,
    required this.horizontalDrift,
    required this.rotationSpeed,
    required this.initialRotation,
    required this.color,
    required this.size,
    required this.isRect,
    required this.startDelay,
    required this.fallDuration,
  });

  final double startXNorm;
  final double startYOffset;
  final double horizontalDrift;
  final double rotationSpeed;
  final double initialRotation;
  final Color color;
  final double size;
  final bool isRect;
  final double startDelay;
  final double fallDuration;

  factory _ConfettiSpec.random(math.Random rng) {
    const colors = [
      Italia90.teamOne,
      Italia90.teamTwo,
      Italia90.green,
      Italia90.red,
      Italia90.ink,
      Colors.white,
    ];
    return _ConfettiSpec(
      startXNorm: rng.nextDouble(),
      startYOffset: -30 - rng.nextDouble() * 140,
      horizontalDrift: (rng.nextDouble() - 0.5) * 180,
      rotationSpeed: (rng.nextDouble() - 0.5) * 10,
      initialRotation: rng.nextDouble() * math.pi * 2,
      color: colors[rng.nextInt(colors.length)],
      size: 3 + rng.nextDouble() * 6,
      isRect: rng.nextBool(),
      startDelay: rng.nextDouble() * 0.08,
      fallDuration: .82 + rng.nextDouble() * .16,
    );
  }

  Offset positionAt(double progress, Size canvasSize) {
    final elapsed = (progress - startDelay).clamp(0.0, double.infinity);
    final fallProgress = (elapsed / fallDuration).clamp(0.0, 1.0).toDouble();
    final easedFall = Curves.easeIn.transform(fallProgress);
    final dx = startXNorm * canvasSize.width + horizontalDrift * fallProgress;
    final dy = startYOffset + (canvasSize.height + 220) * easedFall;
    return Offset(dx, dy);
  }

  double rotationAt(double progress) {
    final elapsed = (progress - startDelay).clamp(0.0, double.infinity);
    return initialRotation + rotationSpeed * elapsed;
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.specs, required this.t});

  final List<_ConfettiSpec> specs;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;

    final paint = Paint();
    for (final s in specs) {
      final pos = s.positionAt(t, size);
      if (pos.dy > size.height + 40 || pos.dy < -60) continue;
      final isOverContent =
          pos.dy > size.height * .28 &&
          pos.dx > size.width * .2 &&
          pos.dx < size.width * .8;
      if (isOverContent) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(s.rotationAt(t));
      paint.color = s.color.withValues(alpha: .78);
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
