import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'design/south_africa_artwork.dart';

class Celebrations {
  Celebrations._();
  static final _goals = Expando<CelebrationOverlayHandle>();

  static CelebrationOverlayHandle showGoal(
    BuildContext context, {
    required Color color,
    required String teamLabel,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _goals[overlay]?.dismiss();
    late final CelebrationOverlayHandle handle;
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
    late final CelebrationOverlayHandle handle;
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

/// Owns the inserted entry even before its first frame; dismissal is idempotent.
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
    with SingleTickerProviderStateMixin, MotionAwareState {
  late final AnimationController _controller;
  late final Timer _hold;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.goal);
    _hold = Timer(AppMotion.goal, widget.onComplete);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion && !_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void settleMotion() {
    _controller.stop();
    _controller.value = .5;
  }

  @override
  void dispose() {
    _hold.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 400;
    final heading = Text(
      'GOAL!',
      textScaler: compact ? TextScaler.noScaling : null,
      style: AppType.event.copyWith(color: AppColors.onTeam(widget.color)),
    );
    final label = Text(
      widget.teamLabel,
      textAlign: TextAlign.center,
      style: AppType.bodyStrong.copyWith(color: AppColors.onTeam(widget.color)),
    );
    return Semantics(
      key: const ValueKey('goal-overlay'),
      container: true,
      liveRegion: true,
      label: 'Goal. ${widget.teamLabel}',
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              final t = _controller.value;
              final opacity = reduceMotion
                  ? 1.0
                  : t < .164
                  ? (t / .164).clamp(0.0, 1.0)
                  : t > .8
                  ? ((1 - t) / .2).clamp(0.0, 1.0)
                  : 1.0;
              return Center(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(
                      reduceMotion
                          ? 0
                          : -16 *
                                (1 -
                                    Curves.easeOutCubic.transform(
                                      (t / .164).clamp(0.0, 1.0),
                                    )),
                      0,
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: compact ? 560 : 360),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(AppRadius.panel),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.panel),
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 32,
                        child: SouthAfricaArtwork(
                          mark: ArtworkMark.headerRibbon,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                        child: compact
                            ? Row(
                                children: [
                                  heading,
                                  const SizedBox(width: 16),
                                  Expanded(child: label),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [heading, label],
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
    required this.onChangeTeams,
    required this.onRematch,
  });
  final Color color;
  final String teamLabel;
  final List<String> playerNames;
  final int winnerScore, loserScore;
  final VoidCallback onChangeTeams, onRematch;
  @override
  State<_VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<_VictoryOverlay>
    with TickerProviderStateMixin, MotionAwareState {
  late final AnimationController _entry, _confetti;
  bool _started = false;
  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: AppMotion.victory);
    _confetti = AnimationController(vsync: this, duration: AppMotion.confetti);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!reduceMotion) {
        _entry.forward();
        _confetti.forward();
      }
    }
  }

  @override
  void settleMotion() {
    _entry.stop();
    _entry.value = 1;
    _confetti.stop();
    _confetti.value = 1;
  }

  @override
  void dispose() {
    _entry.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('victory-overlay'),
    container: true,
    liveRegion: true,
    namesRoute: true,
    scopesRoute: true,
    explicitChildNodes: true,
    label:
        'Vittoria: ${widget.teamLabel}. ${widget.playerNames.join(' e ')}. Punteggio ${widget.winnerScore} a ${widget.loserScore}.',
    child: BlockSemantics(
      child: Material(
        color: AppColors.background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ModalBarrier(
              dismissible: false,
              barrierSemanticsDismissible: false,
              color: Colors.transparent,
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 120,
              child: SouthAfricaArtwork(
                mark: ArtworkMark.headerRibbon,
                fit: BoxFit.fill,
              ),
            ),
            if (!reduceMotion)
              IgnorePointer(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _ConfettiPainter(_confetti),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedBuilder(
                          animation: _entry,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(
                              0,
                              16 *
                                  (1 -
                                      Curves.easeOutCubic.transform(
                                        _entry.value,
                                      )),
                            ),
                            child: child,
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: AppColors.ink,
                                size: 72,
                              ),
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('VITTORIA', style: AppType.event),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: widget.color,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.panel,
                                  ),
                                ),
                                child: DefaultTextStyle(
                                  style: AppType.bodyStrong.copyWith(
                                    color: AppColors.onTeam(widget.color),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        widget.teamLabel,
                                        style: AppType.section.copyWith(
                                          color: AppColors.onTeam(widget.color),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.playerNames.join('  &  '),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${widget.winnerScore} — ${widget.loserScore}',
                                          style: AppType.score.copyWith(
                                            fontSize: 80,
                                            color: AppColors.onTeam(
                                              widget.color,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          autofocus: true,
                          onPressed: widget.onRematch,
                          icon: const Icon(Icons.refresh),
                          label: const Text('RIVINCITA'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: widget.onChangeTeams,
                          icon: const Icon(Icons.groups),
                          label: const Text('CAMBIA SQUADRE'),
                        ),
                      ],
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

/// Fixed bounded ribbon burst; repaint only while the two-second clock runs.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.clock) : super(repaint: clock);
  final Animation<double> clock;
  static const colors = [
    AppColors.yellow,
    AppColors.success,
    AppColors.primary,
    AppColors.error,
  ];
  @override
  void paint(Canvas canvas, Size size) {
    if (clock.value >= 1) return;
    final random = math.Random(2010);
    final paint = Paint();
    for (var i = 0; i < 36; i++) {
      final x = random.nextDouble() * size.width;
      final drift = (random.nextDouble() - .5) * 100;
      final delay = random.nextDouble() * .25;
      final t = math.max(0.0, clock.value - delay);
      canvas.save();
      canvas.translate(x + drift * t, -20 + size.height * 1.6 * t * t);
      canvas.rotate(i + t * 4);
      paint.color = colors[i % colors.length];
      canvas.drawRect(const Rect.fromLTWH(-3, -6, 6, 12), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.clock != clock;
}
