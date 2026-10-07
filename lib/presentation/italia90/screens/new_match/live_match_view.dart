import 'package:flutter/material.dart';

import '../../../../models/match_rules.dart';
import '../../../../models/rivalry_overview.dart';
import '../../theme/app_theme.dart';
import 'live_match_artwork.dart';
import 'live_match_summary.dart';
import 'live_score.dart';
import 'live_team_card.dart';

class LiveMatchView extends StatelessWidget {
  const LiveMatchView({
    super.key,
    required this.rules,
    required this.rivalry,
    required this.team1Names,
    required this.team2Names,
    required this.score1,
    required this.score2,
    required this.isSaving,
    required this.awaitingConfirmation,
    required this.canRegisterResult,
    required this.onAddGoal,
    required this.onRemoveGoal,
    required this.onSave,
    required this.onBack,
    required this.onReset,
  });
  final MatchRules rules;
  final RivalryOverview? rivalry;
  final List<String> team1Names, team2Names;
  final int score1, score2;
  final bool isSaving, awaitingConfirmation, canRegisterResult;
  final ValueChanged<int> onAddGoal, onRemoveGoal;
  final VoidCallback onSave, onBack, onReset;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.35;
      final compact =
          constraints.maxHeight < 600 ||
          largeText ||
          constraints.maxWidth < 360;
      final enabled = !isSaving && !awaitingConfirmation;
      final footer = Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: _ResultButton(
          isSaving: isSaving,
          onSave: canRegisterResult ? onSave : null,
        ),
      );
      final content = <Widget>[
        if (compact)
          _Header(
            onBack: isSaving ? null : onBack,
            onReset: isSaving ? null : onReset,
          ),
        _Scoreboard(score1: score1, score2: score2, compact: compact),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final first = LiveTeamCard(
                team: 1,
                names: team1Names,
                score: score1,
                enabled: enabled,
                onAdd: () => onAddGoal(1),
                onUndo: () => onRemoveGoal(1),
              );
              final second = LiveTeamCard(
                team: 2,
                names: team2Names,
                score: score2,
                enabled: enabled,
                onAdd: () => onAddGoal(2),
                onUndo: () => onRemoveGoal(2),
              );
              if (largeText || bounds.maxWidth < 320) {
                return Column(
                  children: [first, const SizedBox(height: 12), second],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: first),
                  const SizedBox(width: 28),
                  Expanded(child: second),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LiveMatchSummary(
            rules: rules,
            rivalry: rivalry,
            team1Name: team1Names.join(' / '),
            team2Name: team2Names.join(' / '),
          ),
        ),
        const SizedBox(height: 10),
        if (compact) footer,
      ];
      return Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (!compact)
                  _Header(
                    onBack: isSaving ? null : onBack,
                    onReset: isSaving ? null : onReset,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('live-match-scroll'),
                    padding: EdgeInsets.only(
                      bottom: compact
                          ? MediaQuery.paddingOf(context).bottom
                          : 0,
                    ),
                    child: Column(children: content),
                  ),
                ),
                if (!compact) footer,
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onReset});
  final VoidCallback? onBack, onReset;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('new-match-back'),
          onPressed: onBack,
          tooltip: 'Torna alla composizione',
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PARTITA IN CORSO',
                style: AppType.section,
                textAlign: TextAlign.center,
              ),
              Text(
                'DIVERTITI, GIOCA LEALE, SEMPRE',
                textAlign: TextAlign.center,
                style: AppType.caption.copyWith(fontSize: 10, letterSpacing: 1),
              ),
            ],
          ),
        ),
        KeyedSubtree(
          key: const ValueKey('live-match-menu'),
          child: PopupMenuButton<String>(
            key: const ValueKey('new-match-reset'),
            enabled: onReset != null,
            tooltip: 'Altre opzioni partita',
            icon: const Icon(Icons.more_horiz),
            onSelected: (_) => onReset?.call(),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Azzera punteggio'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.score1,
    required this.score2,
    required this.compact,
  });
  final int score1, score2;
  final bool compact;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final ratio = (bounds.maxWidth / 440).clamp(.6, 1.0);
      final scoreHeight = compact ? 110.0 : 200 * ratio;
      final top = 160 * ratio;
      final height = 390 * ratio;
      Widget score(int team, int value) {
        final color = team == 1 ? AppColors.teamOne : AppColors.teamTwo;
        final foreground = AppColors.onTeam(color);
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SQUADRA $team',
                textAlign: TextAlign.center,
                style: AppType.section.copyWith(color: foreground),
              ),
              if (compact)
                LiveScore(
                  team: team,
                  score: value,
                  height: scoreHeight,
                  foregroundColor: foreground,
                )
              else
                Flexible(
                  child: LiveScore(
                    team: team,
                    score: value,
                    height: scoreHeight,
                    foregroundColor: foreground,
                  ),
                ),
            ],
          ),
        );
      }

      if (compact &&
          (bounds.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(22) > 48)) {
        return Column(
          key: const ValueKey('live-illustrated-scoreboard'),
          children: [
            for (final (team, value, color) in [
              (1, score1, AppColors.teamOne),
              (2, score2, AppColors.teamTwo),
            ])
              ColoredBox(
                color: color,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Row(children: [score(team, value)]),
                ),
              ),
          ],
        );
      }
      if (compact) {
        return Stack(
          key: const ValueKey('live-illustrated-scoreboard'),
          children: [
            const Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.teamOne,
                      child: SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: LiveMatchPaints.teamTwoSurface,
                      child: SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [score(1, score1), score(2, score2)],
              ),
            ),
          ],
        );
      }
      return SizedBox(
        key: const ValueKey('live-illustrated-scoreboard'),
        height: height,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: AppColors.teamOne,
                        child: SizedBox.expand(),
                      ),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: AppColors.teamTwo,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: top,
              bottom: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  score(1, score1),
                  SizedBox(
                    width: 32 * ratio,
                    child: Padding(
                      padding: EdgeInsets.only(top: 66 * ratio),
                      child: ExcludeSemantics(
                        child: Text(
                          '–',
                          textAlign: TextAlign.center,
                          style: AppType.event.copyWith(color: AppColors.ink),
                        ),
                      ),
                    ),
                  ),
                  score(2, score2),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ResultButton extends StatelessWidget {
  const _ResultButton({required this.isSaving, required this.onSave});
  final bool isSaving;
  final VoidCallback? onSave;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const ValueKey('live-save-action'),
          onPressed: onSave,
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.flag),
          label: Text(
            isSaving ? 'SALVATAGGIO...' : 'REGISTRA RISULTATO',
            textAlign: TextAlign.center,
          ),
          style: AppTheme.primaryButton().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(48, 56)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            textStyle: WidgetStatePropertyAll(
              AppType.action.copyWith(fontSize: 25),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
          ),
        ),
      ),
    ),
  );
}
