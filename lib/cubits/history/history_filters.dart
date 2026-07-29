import 'package:equatable/equatable.dart';

import '../../models/game_match.dart';

enum HistoryPeriod { all, today, last7Days, last30Days }

enum HistoryMatchModeFilter { all, oneVsOne, twoVsTwo }

enum HistoryResult { all, wins, losses }

class HistoryFilters extends Equatable {
  const HistoryFilters({
    this.matchMode = HistoryMatchModeFilter.all,
    this.period = HistoryPeriod.all,
    this.playerId,
    this.result = HistoryResult.all,
  });

  final HistoryMatchModeFilter matchMode;
  final HistoryPeriod period;
  final String? playerId;
  final HistoryResult result;

  bool get hasActiveFilters {
    return matchMode != HistoryMatchModeFilter.all ||
        period != HistoryPeriod.all ||
        playerId != null ||
        result != HistoryResult.all;
  }

  HistoryFilters copyWith({
    required HistoryMatchModeFilter matchMode,
    required HistoryPeriod period,
    required String? playerId,
    required HistoryResult result,
  }) {
    return HistoryFilters(
      matchMode: matchMode,
      period: period,
      playerId: playerId,
      result: playerId == null ? HistoryResult.all : result,
    );
  }

  HistoryFilters reset() {
    return const HistoryFilters();
  }

  @override
  List<Object?> get props => [matchMode, period, playerId, result];
}

String matchModeLabel(HistoryMatchModeFilter matchMode) {
  switch (matchMode) {
    case HistoryMatchModeFilter.all:
      return 'Tutti i formati';
    case HistoryMatchModeFilter.oneVsOne:
      return '1v1';
    case HistoryMatchModeFilter.twoVsTwo:
      return '2v2';
  }
}

HistoryMatchModeFilter historyMatchModeFilterFor(MatchMode mode) {
  switch (mode) {
    case MatchMode.oneVsOne:
      return HistoryMatchModeFilter.oneVsOne;
    case MatchMode.twoVsTwo:
      return HistoryMatchModeFilter.twoVsTwo;
  }
}

String periodLabel(HistoryPeriod period) {
  switch (period) {
    case HistoryPeriod.all:
      return 'Tutti i risultati';
    case HistoryPeriod.today:
      return 'Oggi';
    case HistoryPeriod.last7Days:
      return 'Ultimi 7 giorni';
    case HistoryPeriod.last30Days:
      return 'Ultimi 30 giorni';
  }
}

String resultLabel(HistoryResult result) {
  switch (result) {
    case HistoryResult.all:
      return 'Tutte';
    case HistoryResult.wins:
      return 'Vinte';
    case HistoryResult.losses:
      return 'Perse';
  }
}
