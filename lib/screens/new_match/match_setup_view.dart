import 'package:flutter/material.dart';

import '../../models/game_match.dart';
import '../../models/match_rules.dart';
import '../../models/player.dart';
import '../../theme/app_theme.dart';
import 'match_options_sheet.dart';
import 'match_setup_controls.dart';
import 'match_setup_roster.dart';
import 'match_team_stage.dart';

const _lowerFlourishAsset =
    'design/south-africa-2010/assets/setup-r2/approved/'
    'lower-flourish-v5-transparent.png';

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
  Widget build(BuildContext context) {
    final requiredPlayers = mode.teamSize * 2;
    final enoughPlayers = present.length >= requiredPlayers;
    final showArtwork = MediaQuery.textScalerOf(context).scale(1) <= 1.35;
    final kickoffHeight =
        (MediaQuery.textScalerOf(context).scale(28) * 1.15 + 24).clamp(
          60.0,
          double.infinity,
        );

    return Stack(
      children: [
        if (showArtwork)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: _LowerFlourish(),
          ),
        SafeArea(
          bottom: false,
          child: ListView(
            key: const ValueKey('setup-scroll-view'),
            padding: EdgeInsets.only(bottom: kickoffHeight + 56),
            children: [
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
                showArtwork: showArtwork,
                players: players,
                team1: team1,
                team2: team2,
                capacity: mode.teamSize,
                enabled: enoughPlayers && !isPersistingRules,
                onAdd: onAddPlayer,
                onEdit: onEditPlayer,
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: _KickoffButton(height: kickoffHeight, onPressed: onKickoff),
        ),
      ],
    );
  }
}

class _LowerFlourish extends StatelessWidget {
  const _LowerFlourish();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return IgnorePointer(
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Transform.translate(
            // The approved PNG ends at alpha row 993, leaving 93 empty rows.
            offset: Offset(0, width * 93 / 1448),
            child: ExcludeSemantics(
              child: Image.asset(
                _lowerFlourishAsset,
                key: const ValueKey('setup-lower-artwork'),
                width: width,
                fit: BoxFit.fitWidth,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KickoffButton extends StatelessWidget {
  const _KickoffButton({required this.height, required this.onPressed});

  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
      child: SizedBox(
        height: height,
        child: ElevatedButton.icon(
          key: const ValueKey('setup-kickoff-action'),
          onPressed: onPressed,
          icon: const Icon(Icons.play_arrow_rounded, size: 34),
          label: const Text('INIZIA PARTITA'),
          style:
              AppTheme.primaryButton(
                background: AppColors.success,
                foreground: AppColors.onPrimary,
                pressed: AppColors.successPressed,
              ).copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                textStyle: WidgetStatePropertyAll(
                  AppType.action.copyWith(fontSize: 28),
                ),
              ),
        ),
      ),
    ),
  );
}
