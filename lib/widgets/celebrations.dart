import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'design/south_africa_artwork.dart';
import 'design/victory_ribbons.dart';

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
    with SingleTickerProviderStateMixin, MotionAwareState {
  late final AnimationController _entry;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: AppMotion.victory);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!reduceMotion) _entry.forward();
    }
  }

  @override
  void settleMotion() {
    _entry.stop();
    _entry.value = 1;
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact =
        media.size.height - media.padding.vertical < 740 ||
        media.textScaler.scale(1) > 1.3;
    return Semantics(
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
              IgnorePointer(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: VictoryRibbons(_entry, compact: compact),
                    ),
                  ),
                ),
              ),
              SafeArea(
                minimum: EdgeInsets.symmetric(vertical: compact ? 40 : 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 24 : 32,
                        vertical: compact ? 40 : 64,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              (constraints.maxHeight - (compact ? 80 : 128))
                                  .clamp(0.0, double.infinity),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AnimatedBuilder(
                                  animation: _entry,
                                  builder: (_, child) {
                                    final reveal = Curves.easeOutCubic
                                        .transform(
                                          ((_entry.value - .45) / .55).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                        );
                                    return ClipRect(
                                      child: Transform.translate(
                                        offset: Offset(0, 100 * (1 - reveal)),
                                        child: Opacity(
                                          opacity: reveal,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'VITTORIA',
                                      style: AppType.event.copyWith(
                                        fontSize: compact ? 64 : 88,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.color,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      widget.teamLabel,
                                      textAlign: TextAlign.center,
                                      style: AppType.section.copyWith(
                                        color: AppColors.onTeam(widget.color),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.playerNames.join('  &  '),
                                  textAlign: TextAlign.center,
                                  style: AppType.player.copyWith(
                                    fontSize: compact ? 22 : 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${widget.winnerScore} — ${widget.loserScore}',
                                    style: AppType.score.copyWith(
                                      fontSize: compact ? 88 : 112,
                                    ),
                                  ),
                                ),
                                SizedBox(height: compact ? 24 : 36),
                                ElevatedButton.icon(
                                  autofocus: true,
                                  style: ElevatedButton.styleFrom(
                                    shape: const StadiumBorder(),
                                    minimumSize: const Size(0, 60),
                                  ),
                                  onPressed: widget.onRematch,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('RIVINCITA'),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: const StadiumBorder(),
                                  ),
                                  onPressed: widget.onChangeTeams,
                                  icon: const Icon(Icons.groups),
                                  label: const Text('CAMBIA SQUADRE'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
