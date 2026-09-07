import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'team_slot.dart';

class ScorePanel extends StatefulWidget {
  const ScorePanel({
    super.key,
    required this.teamNumber,
    required this.label,
    required this.color,
    required this.playerNames,
    required this.score,
    required this.enabled,
    required this.onAddGoal,
    required this.onRemoveGoal,
  });
  final int teamNumber, score;
  final String label;
  final Color color;
  final List<String> playerNames;
  final bool enabled;
  final VoidCallback onAddGoal, onRemoveGoal;
  @override
  State<ScorePanel> createState() => _ScorePanelState();
}

class _ScorePanelState extends State<ScorePanel>
    with SingleTickerProviderStateMixin, MotionAwareState {
  late final AnimationController _score;
  @override
  void initState() {
    super.initState();
    _score = AnimationController(
      vsync: this,
      duration: AppMotion.score,
      value: 1,
    );
  }

  @override
  void settleMotion() {
    _score.stop();
    _score.value = 1;
  }

  @override
  void didUpdateWidget(covariant ScorePanel oldWidget) {
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
  Widget build(BuildContext context) {
    final foreground = AppColors.onTeam(widget.color);
    final undo = widget.enabled && widget.score > 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.panel),
      child: ColoredBox(
        color: AppColors.teamContainer(widget.color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 172),
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                16,
                                12,
                                12,
                              ),
                              color: widget.color,
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      widget.label,
                                      textAlign: TextAlign.center,
                                      style: AppType.section.copyWith(
                                        color: foreground,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: Center(
                                      child: SizedBox(
                                        height: 112,
                                        child: Semantics(
                                          key: ValueKey(
                                            'score-team-${widget.teamNumber}',
                                          ),
                                          container: true,
                                          liveRegion: true,
                                          label:
                                              'Punteggio ${widget.label}: ${widget.score}',
                                          child: ExcludeSemantics(
                                            child: AnimatedBuilder(
                                              animation: _score,
                                              builder: (_, child) =>
                                                  Transform.scale(
                                                    scale:
                                                        1 +
                                                        .06 *
                                                            math.sin(
                                                              _score.value *
                                                                  math.pi,
                                                            ),
                                                    child: child,
                                                  ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  '${widget.score}',
                                                  style: AppType.score.copyWith(
                                                    color: foreground,
                                                  ),
                                                ),
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
                          for (final name in widget.playerNames)
                            TeamSlot(name: name, teamColor: widget.color),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    key: ValueKey('score-add-team-${widget.teamNumber}'),
                    container: true,
                    button: true,
                    enabled: widget.enabled,
                    label:
                        'Aggiungi un goal a ${widget.label}. Punteggio attuale ${widget.score}.',
                    onTap: widget.enabled ? widget.onAddGoal : null,
                    child: ExcludeSemantics(
                      child: ElevatedButton(
                        onPressed: widget.enabled ? widget.onAddGoal : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          foregroundColor: foreground,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('+1 GOAL'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    key: ValueKey('score-undo-team-${widget.teamNumber}'),
                    container: true,
                    button: true,
                    enabled: undo,
                    label: 'Annulla ultimo goal di ${widget.label}',
                    onTap: undo ? widget.onRemoveGoal : null,
                    child: ExcludeSemantics(
                      child: TextButton.icon(
                        onPressed: undo ? widget.onRemoveGoal : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                        ),
                        icon: const Icon(Icons.remove, size: 16),
                        label: const Text('Annulla'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
