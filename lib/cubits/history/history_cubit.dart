import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/player_repository.dart';
import 'history_filters.dart';
import 'history_logic.dart';
import 'history_state.dart';

typedef ClockFn = DateTime Function();

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required PlayerRepository playerRepository,
    required MatchRepository matchRepository,
    ClockFn? clock,
  })  : _playerRepo = playerRepository,
        _matchRepo = matchRepository,
        _clock = clock ?? DateTime.now,
        super(const HistoryState()) {
    _players = _playerRepo.players;
    _matches = _matchRepo.matches;
    _recompute();
    _playersSub = _playerRepo.watchPlayers().listen((players) {
      _players = players;
      _recompute();
    });
    _matchesSub = _matchRepo.watchMatches().listen((matches) {
      _matches = matches;
      _recompute();
    });
  }

  final PlayerRepository _playerRepo;
  final MatchRepository _matchRepo;
  final ClockFn _clock;
  late final StreamSubscription<List<Player>> _playersSub;
  late final StreamSubscription<List<GameMatch>> _matchesSub;

  List<Player> _players = const [];
  List<GameMatch> _matches = const [];

  void applyFilters(HistoryFilters filters) {
    if (state.filters == filters) return;
    _recompute(filters: filters);
  }

  void resetFilters() {
    if (!state.filters.hasActiveFilters) return;
    _recompute(filters: const HistoryFilters());
  }

  Future<void> deleteMatch(GameMatch match) async {
    await _matchRepo.deleteMatch(match.id);
  }

  Future<void> updateMatch(GameMatch match) async {
    await _matchRepo.updateMatch(match);
  }

  void _recompute({HistoryFilters? filters}) {
    final activeFilters = filters ?? state.filters;
    final now = _clock();
    final filtered = filterMatches(_matches, activeFilters, now);
    final groups = groupMatchesByDay(filtered);
    final label = filterSummaryLabel(_players, activeFilters);
    emit(state.copyWith(
      players: _players,
      filters: activeFilters,
      filteredMatches: filtered,
      groups: groups,
      filterLabel: label,
    ));
  }

  @override
  Future<void> close() async {
    await _playersSub.cancel();
    await _matchesSub.cancel();
    return super.close();
  }
}
