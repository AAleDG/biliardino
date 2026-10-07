import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Score feedback keeps the existing timing, pulse and runtime motion policy.
class LiveScore extends StatefulWidget {
  const LiveScore({
    super.key,
    required this.team,
    required this.score,
    required this.height,
    required this.foregroundColor,
  });
  final int team, score;
  final double height;
  final Color foregroundColor;
  @override
  State<LiveScore> createState() => _LiveScoreState();
}

class _LiveScoreState extends State<LiveScore>
    with SingleTickerProviderStateMixin, MotionAwareState {
  late final AnimationController _score = AnimationController(
    vsync: this,
    duration: AppMotion.score,
    value: 1,
  );
  @override
  void settleMotion() {
    _score.stop();
    _score.value = 1;
  }

  @override
  void didUpdateWidget(covariant LiveScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      if (reduceMotion) {
        settleMotion();
      } else {
        _score.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _score.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('score-team-${widget.team}'),
    container: true,
    liveRegion: true,
    label: 'Punteggio SQUADRA ${widget.team}: ${widget.score}',
    child: ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: Padding(
          // Wide scores must remain inside the curved colored field.
          padding: EdgeInsets.symmetric(
            horizontal: widget.score >= 10 ? 20 : 6,
          ),
          child: AnimatedBuilder(
            animation: _score,
            builder: (_, child) => Transform.scale(
              key: ValueKey('score-pulse-${widget.team}'),
              scale: 1 + .06 * math.sin(_score.value * math.pi),
              child: child,
            ),
            child: FittedBox(
              child: Text(
                '${widget.score}',
                style: AppType.score.copyWith(
                  fontSize: 200,
                  color: widget.foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
