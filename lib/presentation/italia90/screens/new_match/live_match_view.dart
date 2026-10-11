import 'package:flutter/material.dart';

import '../../../../models/match_rules.dart';
import '../../../../models/player.dart';
import '../../../../models/rivalry_overview.dart';
import '../../theme/app_theme.dart';
import '../../theme/italia90_tokens.dart';
import '../../widgets/italia90_components.dart';
import 'live_poster_header.dart';
import 'live_match_summary.dart';

class LiveMatchView extends StatelessWidget {
  const LiveMatchView({
    super.key,
    required this.rules,
    required this.rivalry,
    required this.team1Players,
    required this.team2Players,
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
  final List<Player> team1Players, team2Players;
  final int score1, score2;
  final bool isSaving, awaitingConfirmation, canRegisterResult;
  final void Function(int team, String playerId) onAddGoal;
  final ValueChanged<int> onRemoveGoal;
  final VoidCallback onSave, onBack, onReset;

  @override
  Widget build(BuildContext context) {
    final enabled = !isSaving && !awaitingConfirmation;
    final first = TeamScorePanel(
      key: const ValueKey('live-team-panel-1'),
      team: ItaliaTeam.one,
      players: team1Players,
      score: score1,
      enabled: enabled,
      onAdd: (playerId) => onAddGoal(1, playerId),
      onUndo: () => onRemoveGoal(1),
    );
    final second = TeamScorePanel(
      key: const ValueKey('live-team-panel-2'),
      team: ItaliaTeam.two,
      players: team2Players,
      score: score2,
      enabled: enabled,
      onAdd: (playerId) => onAddGoal(2, playerId),
      onUndo: () => onRemoveGoal(2),
    );
    final actionRow = Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: _LiveMatchActions(
        first: first,
        second: second,
        isSaving: isSaving,
        onSave: canRegisterResult ? onSave : null,
      ),
    );
    final hasSummary =
        !rules.isFree ||
        (rivalry != null && team1Players.isNotEmpty && team2Players.isNotEmpty);
    final liveBoard = ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: ColoredBox(
        color: Italia90.surface,
        child: Column(
          children: [
            Semantics(
              container: true,
              label: "Italia '90. Partita in corso",
              child: Column(
                children: [
                  LivePosterHeader(
                    onBack: isSaving ? null : onBack,
                    onReset: isSaving ? null : onReset,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ItaliaScoreboard(
                      key: const ValueKey('live-illustrated-scoreboard'),
                      showUndo: false,
                      first: first,
                      second: second,
                    ),
                  ),
                ],
              ),
            ),
            actionRow,
            if (hasSummary)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: LiveMatchSummary(
                  rules: rules,
                  rivalry: rivalry,
                  team1Name: team1Players
                      .map((player) => player.name)
                      .join(' / '),
                  team2Name: team2Players
                      .map((player) => player.name)
                      .join(' / '),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('live-match-scroll'),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 12,
                  ),
                  child: liveBoard,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveMatchActions extends StatelessWidget {
  const _LiveMatchActions({
    required this.first,
    required this.second,
    required this.isSaving,
    required this.onSave,
  });

  final TeamScorePanel first;
  final TeamScorePanel second;
  final bool isSaving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
      final stack = largeText || constraints.maxWidth < 340;
      final undo = ItaliaSharedUndoAction(first: first, second: second);
      final save = _ResultButton(isSaving: isSaving, onSave: onSave);
      if (stack) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [undo, const SizedBox(height: 8), save],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: undo),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: save),
        ],
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
    decoration: const BoxDecoration(color: Colors.transparent),
    child: ClipPath(
      clipper: const _ItaliaTicketClipper(),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const ValueKey('live-save-action'),
          onPressed: onSave,
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const SizedBox.shrink(),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isSaving ? 'SALVATAGGIO...' : 'REGISTRA RISULTATO',
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
            ),
          ),
          style:
              AppTheme.primaryButton(
                background: AppColors.error,
                foreground: Colors.white,
                pressed: AppColors.primaryPressed,
              ).copyWith(
                minimumSize: const WidgetStatePropertyAll(Size(48, 64)),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                textStyle: WidgetStatePropertyAll(
                  AppType.action.copyWith(fontSize: 22, letterSpacing: 1),
                ),
                shape: const WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
        ),
      ),
    ),
  );
}

class _ItaliaTicketClipper extends CustomClipper<Path> {
  const _ItaliaTicketClipper();

  @override
  Path getClip(Size size) {
    const notch = 8.0;
    final path = Path()
      ..moveTo(notch, 0)
      ..lineTo(size.width - notch, 0)
      ..lineTo(size.width - notch, notch)
      ..arcToPoint(
        Offset(size.width - notch, notch * 3),
        radius: const Radius.circular(notch),
        clockwise: false,
      )
      ..lineTo(size.width - notch, size.height - notch * 3)
      ..arcToPoint(
        Offset(size.width - notch, size.height - notch),
        radius: const Radius.circular(notch),
        clockwise: false,
      )
      ..lineTo(size.width - notch, size.height)
      ..lineTo(notch, size.height)
      ..lineTo(notch, size.height - notch)
      ..arcToPoint(
        Offset(notch, size.height - notch * 3),
        radius: const Radius.circular(notch),
      )
      ..lineTo(notch, notch * 3)
      ..arcToPoint(
        const Offset(notch, notch),
        radius: const Radius.circular(notch),
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_ItaliaTicketClipper oldClipper) => false;
}
