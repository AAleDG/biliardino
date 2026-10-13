import 'package:flutter/material.dart';

import '../../../../models/game_match.dart';
import '../../../../models/match_rules.dart';
import '../../../../models/player.dart';
import '../../../../models/rivalry_overview.dart';
import '../../theme/app_theme.dart';
import '../../theme/italia90_tokens.dart';
import '../../widgets/italia90_components.dart';
import 'live_match_summary.dart';
import 'live_poster_header.dart';

class LiveMatchView extends StatelessWidget {
  const LiveMatchView({
    super.key,
    required this.mode,
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
    this.showInteractivePanel = true,
  });
  final MatchMode mode;
  final MatchRules rules;
  final RivalryOverview? rivalry;
  final List<Player> team1Players, team2Players;
  final int score1, score2;
  final bool isSaving, awaitingConfirmation, canRegisterResult;
  final void Function(int team, String playerId) onAddGoal;
  final ValueChanged<int> onRemoveGoal;
  final VoidCallback onSave, onBack, onReset;
  final bool showInteractivePanel;

  @override
  Widget build(BuildContext context) {
    final enabled = !isSaving && !awaitingConfirmation;
    final visibleTeam1Players = team1Players.take(mode.teamSize).toList();
    final visibleTeam2Players = team2Players.take(mode.teamSize).toList();
    final first = TeamScorePanel(
      key: const ValueKey('live-team-panel-1'),
      team: ItaliaTeam.one,
      players: visibleTeam1Players,
      score: score1,
      enabled: enabled,
      onAdd: (playerId) => onAddGoal(1, playerId),
      onUndo: () => onRemoveGoal(1),
    );
    final second = TeamScorePanel(
      key: const ValueKey('live-team-panel-2'),
      team: ItaliaTeam.two,
      players: visibleTeam2Players,
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
        (rivalry != null &&
            visibleTeam1Players.isNotEmpty &&
            visibleTeam2Players.isNotEmpty);
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
                    onReset: isSaving ? null : onReset,
                    overlay: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (!showInteractivePanel)
                          _LivePosterScoreOverlay(
                            score1: score1,
                            score2: score2,
                          ),
                      ],
                    ),
                  ),
                  if (showInteractivePanel)
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
            if (!showInteractivePanel)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final largeText =
                        MediaQuery.textScalerOf(context).scale(16) > 22;
                    final rosters = [
                      for (final panel in [first, second])
                        ItaliaTeamRoster(
                          key: ValueKey('live-roster-team-${panel.team.number}'),
                          team: panel.team,
                          players: panel.players,
                          largeText: largeText,
                          enabled: enabled,
                          score: panel.score,
                          onAdd: panel.onAdd,
                          avatar: _LivePosterPlayerBadge(
                            team: panel.team,
                            size: mode == MatchMode.oneVsOne ? 88 : 64,
                          ),
                          nameStyle: Italia90.heading.copyWith(
                            fontSize: mode == MatchMode.oneVsOne ? 22 : 18,
                            height: 1.2,
                          ),
                        ),
                    ];
                    if (largeText || constraints.maxWidth < 300) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          rosters[0],
                          const SizedBox(height: 16),
                          rosters[1],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: rosters[0]),
                        const SizedBox(width: 16),
                        Expanded(child: rosters[1]),
                      ],
                    );
                  },
                ),
              ),
            actionRow,
            if (hasSummary)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: LiveMatchSummary(
                  rules: rules,
                  rivalry: rivalry,
                  team1Name: visibleTeam1Players
                      .map((player) => player.name)
                      .join(' / '),
                  team2Name: visibleTeam2Players
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
        Positioned(
          top: MediaQuery.paddingOf(context).top + 4,
          left: 4,
          child: _LiveMatchBackButton(onPressed: isSaving ? null : onBack),
        ),
      ],
    );
  }
}

class _LiveMatchBackButton extends StatelessWidget {
  const _LiveMatchBackButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const ValueKey('new-match-back'),
    child: Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Torna alla composizione',
        icon: const Icon(Icons.arrow_back),
        color: Italia90.ink,
        padding: EdgeInsets.zero,
        style: const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
        constraints: const BoxConstraints.tightFor(
          width: Italia90.touch,
          height: Italia90.touch,
        ),
      ),
    ),
  );
}

class _LivePosterPlayerBadge extends StatelessWidget {
  const _LivePosterPlayerBadge({required this.team, required this.size});

  final ItaliaTeam team;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Reuse only the figure from the original poster, never its sample names
    // or baked-in controls.
    final scale = size / 156;
    final sourceLeft = team == ItaliaTeam.one ? 52.0 : 518.0;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: LivePosterHeader.sourceWidth * scale,
            maxWidth: LivePosterHeader.sourceWidth * scale,
            minHeight: LivePosterHeader.sourceHeight * scale,
            maxHeight: LivePosterHeader.sourceHeight * scale,
            child: Transform.translate(
              offset: Offset(-sourceLeft * scale, -1038 * scale),
              child: Image.asset(
                'assets/italia90/live-poster-editoriale.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LivePosterScoreOverlay extends StatelessWidget {
  const _LivePosterScoreOverlay({required this.score1, required this.score2});

  final int score1;
  final int score2;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const divider = .008;
      final halfWidth = constraints.maxWidth * .5;
      final dividerWidth = constraints.maxWidth * divider;
      final sourceHeight = LivePosterHeader.sourceHeightForWidth(
        constraints.maxWidth,
      );
      final scoreTop = sourceHeight * .285;
      final scoreHeight = sourceHeight * .29;
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            top: scoreTop,
            width: halfWidth - dividerWidth / 2,
            height: scoreHeight,
            child: _PosterScoreBlock(team: ItaliaTeam.one, score: score1),
          ),
          Positioned(
            left: halfWidth + dividerWidth / 2,
            top: scoreTop,
            width: halfWidth - dividerWidth / 2,
            height: scoreHeight,
            child: _PosterScoreBlock(team: ItaliaTeam.two, score: score2),
          ),
        ],
      );
    },
  );
}

class _PosterScoreBlock extends StatelessWidget {
  const _PosterScoreBlock({required this.team, required this.score});

  final ItaliaTeam team;
  final int score;

  @override
  Widget build(BuildContext context) {
    final background = team == ItaliaTeam.one
        ? const Color(0xFF074DC8)
        : const Color(0xFFF7CC2F);
    return ColoredBox(
      color: background,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: 'Punteggio ${team.label.toUpperCase()}: $score',
        child: ExcludeSemantics(
          child: Center(
            child: ItaliaScoreValue(
              score: score,
              fit: BoxFit.contain,
              style: Italia90.score.copyWith(
                color: team.onColor,
                fontSize: 400,
                height: .86,
              ),
            ),
          ),
        ),
      ),
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
          label: Text(
            isSaving ? 'SALVATAGGIO...' : 'REGISTRA RISULTATO',
            textAlign: TextAlign.center,
            softWrap: true,
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
