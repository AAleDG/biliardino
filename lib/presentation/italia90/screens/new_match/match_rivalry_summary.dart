import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../models/game_match.dart';
import '../../../../models/player.dart';
import '../../../../services/stats_service.dart';
import '../../theme/app_theme.dart';

class MatchRivalrySummary extends StatefulWidget {
  const MatchRivalrySummary({
    super.key,
    required this.matches,
    required this.players,
    required this.team1,
    required this.team2,
  });

  final List<GameMatch> matches;
  final List<Player> players;
  final List<String> team1;
  final List<String> team2;

  @override
  State<MatchRivalrySummary> createState() => _MatchRivalrySummaryState();
}

class _MatchRivalrySummaryState extends State<MatchRivalrySummary> {
  late String _summary;

  @override
  void initState() {
    super.initState();
    _summary = _deriveSummary();
  }

  @override
  void didUpdateWidget(MatchRivalrySummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameList(oldWidget.matches, widget.matches) ||
        !_sameList(oldWidget.players, widget.players) ||
        !_sameList(oldWidget.team1, widget.team1) ||
        !_sameList(oldWidget.team2, widget.team2)) {
      _summary = _deriveSummary();
    }
  }

  String _deriveSummary() {
    final overview = StatsService.rivalryOverview(
      widget.matches,
      team1Ids: widget.team1,
      team2Ids: widget.team2,
    );
    String label(List<String> ids) => ids
        .map((id) => StatsService.playerName(widget.players, id))
        .join(' / ');
    final team1 = label(widget.team1);
    final team2 = label(widget.team2);
    return overview.hasMatches
        ? '$team1 vs $team2 · ${overview.team1Wins}-${overview.team2Wins} nei duelli'
        : 'Primo duello tra $team1 e $team2.';
  }

  @override
  Widget build(BuildContext context) => Text(
    _summary,
    style: AppType.caption.copyWith(color: AppColors.textSecondary),
  );
}

bool _sameList<T>(List<T> first, List<T> second) =>
    identical(first, second) || listEquals(first, second);
