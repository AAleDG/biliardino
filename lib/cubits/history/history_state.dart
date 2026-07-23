import 'package:equatable/equatable.dart';

import '../../models/game_match.dart';
import '../../models/player.dart';
import 'history_filters.dart';
import 'history_logic.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.players = const [],
    this.filters = const HistoryFilters(),
    this.filteredMatches = const [],
    this.groups = const [],
    this.filterLabel = 'Tutti i risultati',
  });

  final List<Player> players;
  final HistoryFilters filters;
  final List<GameMatch> filteredMatches;
  final List<MatchDayGroup> groups;
  final String filterLabel;

  bool get hasActiveFilters => filters.hasActiveFilters;
  DateTime? get lastMatchAt =>
      filteredMatches.isEmpty ? null : filteredMatches.first.playedAt;
  int get matchesCount => filteredMatches.length;

  HistoryState copyWith({
    List<Player>? players,
    HistoryFilters? filters,
    List<GameMatch>? filteredMatches,
    List<MatchDayGroup>? groups,
    String? filterLabel,
  }) {
    return HistoryState(
      players: players ?? this.players,
      filters: filters ?? this.filters,
      filteredMatches: filteredMatches ?? this.filteredMatches,
      groups: groups ?? this.groups,
      filterLabel: filterLabel ?? this.filterLabel,
    );
  }

  @override
  List<Object?> get props =>
      [players, filters, filteredMatches, groups, filterLabel];
}
