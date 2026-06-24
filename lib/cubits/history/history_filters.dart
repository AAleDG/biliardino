import 'package:equatable/equatable.dart';

enum HistoryPeriod { all, today, last7Days, last30Days }

enum HistoryResult { all, wins, losses }

class HistoryFilters extends Equatable {
  const HistoryFilters({
    this.period = HistoryPeriod.all,
    this.playerId,
    this.result = HistoryResult.all,
  });

  final HistoryPeriod period;
  final String? playerId;
  final HistoryResult result;

  bool get hasActiveFilters {
    return period != HistoryPeriod.all ||
        playerId != null ||
        result != HistoryResult.all;
  }

  HistoryFilters copyWith({
    required HistoryPeriod period,
    required String? playerId,
    required HistoryResult result,
  }) {
    return HistoryFilters(
      period: period,
      playerId: playerId,
      result: playerId == null ? HistoryResult.all : result,
    );
  }

  HistoryFilters reset() {
    return const HistoryFilters();
  }

  @override
  List<Object?> get props => [period, playerId, result];
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
