import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../services/stats_service.dart';
import 'history_filters.dart';

class MatchDayGroup {
  const MatchDayGroup({required this.day, required this.matches});

  final DateTime day;
  final List<GameMatch> matches;

  MatchDayGroup copyWith({required List<GameMatch> matches}) {
    return MatchDayGroup(day: day, matches: matches);
  }
}

List<GameMatch> filterMatches(
  List<GameMatch> matches,
  HistoryFilters filters,
  DateTime now,
) {
  final periodStart = periodStartDate(filters.period, now);
  return StatsService.sortedByMostRecent(matches).where((match) {
    if (filters.matchMode != HistoryMatchModeFilter.all &&
        historyMatchModeFilterFor(match.mode) != filters.matchMode) {
      return false;
    }
    if (periodStart != null && match.playedAt.isBefore(periodStart)) {
      return false;
    }
    if (filters.playerId != null &&
        !match.allPlayers.contains(filters.playerId)) {
      return false;
    }
    if (filters.result == HistoryResult.wins &&
        !match.winners.contains(filters.playerId)) {
      return false;
    }
    if (filters.result == HistoryResult.losses &&
        !match.losers.contains(filters.playerId)) {
      return false;
    }
    return true;
  }).toList();
}

DateTime? periodStartDate(HistoryPeriod period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (period) {
    case HistoryPeriod.all:
      return null;
    case HistoryPeriod.today:
      return today;
    case HistoryPeriod.last7Days:
      return today.subtract(const Duration(days: 6));
    case HistoryPeriod.last30Days:
      return today.subtract(const Duration(days: 29));
  }
}

String filterSummaryLabel(
  List<Player> players,
  HistoryFilters filters,
) {
  final parts = <String>[
    if (filters.matchMode != HistoryMatchModeFilter.all)
      matchModeLabel(filters.matchMode),
    periodLabel(filters.period),
    if (filters.playerId != null)
      StatsService.playerName(players, filters.playerId!),
    if (filters.result != HistoryResult.all && filters.playerId != null)
      resultLabel(filters.result),
  ];
  return parts.join(' · ');
}

List<MatchDayGroup> groupMatchesByDay(List<GameMatch> matches) {
  final groups = <MatchDayGroup>[];
  for (final match in matches) {
    final day = DateTime(
      match.playedAt.year,
      match.playedAt.month,
      match.playedAt.day,
    );
    if (groups.isEmpty || groups.last.day != day) {
      groups.add(MatchDayGroup(day: day, matches: [match]));
    } else {
      groups[groups.length - 1] = groups.last.copyWith(
        matches: [...groups.last.matches, match],
      );
    }
  }
  return groups;
}

String dayLabel(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (day == today) {
    return 'Oggi';
  }
  if (day == yesterday) {
    return 'Ieri';
  }
  return '${day.day} ${_italianMonth(day.month)} ${day.year}';
}

String _italianMonth(int month) {
  const months = [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];
  return months[month - 1];
}
