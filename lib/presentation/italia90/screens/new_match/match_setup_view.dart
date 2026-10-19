import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../models/game_match.dart';
import '../../../../models/match_rules.dart';
import '../../../../models/player.dart';
import '../../theme/app_theme.dart';
import 'match_options_sheet.dart';
import 'match_setup_controls.dart';
import 'match_setup_roster.dart';
import 'match_team_stage.dart';

class MatchSetupView extends StatelessWidget {
  const MatchSetupView({
    super.key,
    required this.players,
    required this.mode,
    required this.rules,
    required this.isPersistingRules,
    required this.isRivalry,
    required this.present,
    required this.team1,
    required this.team2,
    required this.assignment,
    required this.onModeChanged,
    required this.onOptionsPressed,
    required this.onShowAllPlayers,
    required this.onAddPlayer,
    required this.onEditPlayer,
    required this.onKickoff,
  });

  final List<Player> players;
  final MatchMode mode;
  final MatchRules rules;
  final bool isPersistingRules;
  final bool isRivalry;
  final List<Player> present;
  final List<String> team1;
  final List<String> team2;
  final Map<String, int> assignment;
  final ValueChanged<MatchMode> onModeChanged;
  final VoidCallback onOptionsPressed;
  final VoidCallback onShowAllPlayers;
  final ValueChanged<int> onAddPlayer;
  final void Function(int team, String playerId) onEditPlayer;
  final VoidCallback? onKickoff;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final requiredPlayers = mode.teamSize * 2;
      final enoughPlayers = present.length >= requiredPlayers;
      final textScaler = MediaQuery.textScalerOf(context);
      final verticalKickoff = textScaler.scale(28) > 56;
      final kickoffHeight = _kickoffButtonHeight(
        context,
        constraints.maxWidth,
        verticalLayout: verticalKickoff,
      );
      final scrollKickoff = _shouldScrollKickoff(constraints);
      final content = <Widget>[
        const MatchSetupHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: MatchModeSelector(
            selectedMode: mode,
            onChanged: isPersistingRules ? null : onModeChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: MatchOptionsSummary(
            rules: rules,
            isRivalry: isRivalry,
            onPressed: onOptionsPressed,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: MatchRosterSummary(
            players: present.take(4).toList(growable: false),
            totalCount: present.length,
            assignment: assignment,
            enoughPlayers: enoughPlayers,
            neededMessage:
                'Servono almeno $requiredPlayers giocatori presenti per '
                'una partita ${matchModeTitle(mode)}.',
            onShowAll: present.length > 4 ? onShowAllPlayers : null,
          ),
        ),
        const SizedBox(height: 6),
        MatchTeamStage(
          players: players,
          team1: team1,
          team2: team2,
          capacity: mode.teamSize,
          enabled: enoughPlayers && !isPersistingRules,
          onAdd: onAddPlayer,
          onEdit: onEditPlayer,
        ),
        if (scrollKickoff)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: _KickoffButton(
              minHeight: kickoffHeight,
              verticalLayout: verticalKickoff,
              onPressed: onKickoff,
            ),
          ),
      ];

      return Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              key: const ValueKey('setup-scroll-view'),
              padding: EdgeInsets.only(
                bottom: scrollKickoff ? 56 : kickoffHeight + 56,
              ),
              children: content,
            ),
          ),
          if (!scrollKickoff)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: _KickoffButton(
                minHeight: kickoffHeight,
                verticalLayout: verticalKickoff,
                onPressed: onKickoff,
              ),
            ),
        ],
      );
    },
  );
}

bool _shouldScrollKickoff(BoxConstraints constraints) {
  if (!constraints.hasBoundedHeight) return false;

  // Keep the action in the same scroll view when a large label can cover the
  // team rows in a short portrait or landscape viewport.
  return constraints.maxHeight < 600;
}

double _kickoffButtonHeight(
  BuildContext context,
  double viewportWidth, {
  required bool verticalLayout,
}) {
  final textScaler = MediaQuery.textScalerOf(context);
  final labelStyle = AppType.action.copyWith(fontSize: 28);
  final actionWidth = viewportWidth.isFinite
      ? math.max(0.0, viewportWidth - 32).toDouble()
      : 320.0;
  final buttonWidth = math.max(1.0, actionWidth - 8).toDouble();
  final labelWidth = verticalLayout
      ? math.max(1.0, buttonWidth - 24).toDouble()
      : math.max(1.0, buttonWidth - 24 - 34 - 8).toDouble();
  final labelPainter = TextPainter(
    text: TextSpan(text: 'INIZIA PARTITA', style: labelStyle),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: labelWidth);
  final contentHeight = verticalLayout
      ? 34 + 4 + labelPainter.height
      : math.max(labelPainter.height, 34.0).toDouble();
  return math.max(60.0, contentHeight + 16).toDouble();
}

class _KickoffButton extends StatelessWidget {
  const _KickoffButton({
    required this.minHeight,
    required this.verticalLayout,
    required this.onPressed,
  });

  final double minHeight;
  final bool verticalLayout;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style =
        AppTheme.primaryButton(
          background: AppColors.homeAction,
          foreground: AppColors.onPrimary,
          pressed: AppColors.homeActionPressed,
        ).copyWith(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          textStyle: WidgetStatePropertyAll(
            AppType.action.copyWith(fontSize: 28),
          ),
        );
    final content = verticalLayout
        ? const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, size: 34),
              SizedBox(height: 4),
              Flexible(
                child: Text('INIZIA PARTITA', textAlign: TextAlign.center),
              ),
            ],
          )
        : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, size: 34),
              SizedBox(width: 8),
              Flexible(
                child: Text('INIZIA PARTITA', textAlign: TextAlign.center),
              ),
            ],
          );
    final button = ElevatedButton(
      key: const ValueKey('setup-kickoff-action'),
      onPressed: onPressed,
      style: style,
      child: content,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: button,
        ),
      ),
    );
  }
}
