import 'package:flutter/material.dart';
import '../../models/match_rules.dart';
import '../../models/rivalry_overview.dart';
import '../../theme/app_theme.dart';

class LiveMatchSummary extends StatelessWidget {
  const LiveMatchSummary({
    super.key,
    required this.rules,
    required this.rivalry,
    required this.team1Name,
    required this.team2Name,
  });
  final MatchRules rules;
  final RivalryOverview? rivalry;
  final String team1Name, team2Name;
  @override
  Widget build(BuildContext context) {
    final text = rules.isFree
        ? 'PUNTEGGIO LIBERO'
        : 'PRIMO A ${rules.targetScore}${rules.winByTwo ? ' · +2' : ''}';
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.divider.withValues(alpha: .25),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppType.utility,
          ),
        ),
        if (rivalry != null && team1Name.isNotEmpty && team2Name.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                const Text('RIVALITA ATTIVA', style: AppType.utility),
                const SizedBox(height: 4),
                Text(
                  _rivalryHeadline(rivalry!, team1Name, team2Name),
                  textAlign: TextAlign.center,
                  style: AppType.bodyStrong,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _rivalryHeadline(
  RivalryOverview overview,
  String team1Name,
  String team2Name,
) {
  if (!overview.hasMatches) {
    return 'Nessun precedente tra $team1Name e $team2Name.';
  }
  if (overview.isTied) {
    return '$team1Name e $team2Name sono in parita: ${overview.team1Wins}-${overview.team2Wins} nei duelli diretti.';
  }
  final leaderName = overview.team1Wins > overview.team2Wins
      ? team1Name
      : team2Name;
  return '$leaderName conduce ${overview.team1Wins}-${overview.team2Wins}, con ${overview.team1Goals}-${overview.team2Goals} nei gol assegnati.';
}
