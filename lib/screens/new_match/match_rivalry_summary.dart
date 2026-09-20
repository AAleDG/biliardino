import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../models/rivalry_overview.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';

class MatchRivalrySummary extends StatelessWidget {
  const MatchRivalrySummary({
    super.key,
    required this.overview,
    required this.players,
  });

  final RivalryOverview overview;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    String label(List<String> ids) =>
        ids.map((id) => StatsService.playerName(players, id)).join(' / ');
    final team1 = label(overview.team1Ids);
    final team2 = label(overview.team2Ids);
    final summary = overview.hasMatches
        ? '$team1 vs $team2 · ${overview.team1Wins}-${overview.team2Wins} nei duelli'
        : 'Primo duello tra $team1 e $team2.';
    return Text(
      summary,
      style: AppType.caption.copyWith(color: AppColors.textSecondary),
    );
  }
}
