import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../models/team_leaderboard_stats.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/player_repository.dart';
import '../../services/stats_service.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit({
    required PlayerRepository playerRepository,
    required MatchRepository matchRepository,
  }) : _playerRepo = playerRepository,
       _matchRepo = matchRepository,
       super(
         LeaderboardState(selectedMode: _defaultMode(matchRepository.matches)),
       ) {
    _players = _playerRepo.players;
    _matches = _matchRepo.matches;
    _recompute();
    _playersSub = _playerRepo.watchPlayers().listen((players) {
      if (identical(players, _players)) return;
      _players = players;
      _recompute();
    });
    _matchesSub = _matchRepo.watchMatches().listen((matches) {
      if (identical(matches, _matches)) return;
      _matches = matches;
      _recompute();
    });
  }

  final PlayerRepository _playerRepo;
  final MatchRepository _matchRepo;
  late final StreamSubscription<List<Player>> _playersSub;
  late final StreamSubscription<List<GameMatch>> _matchesSub;

  List<Player> _players = const [];
  List<GameMatch> _matches = const [];

  void _recompute({MatchMode? mode}) {
    final selectedMode = mode ?? state.selectedMode;
    final modeMatches = _matches
        .where((match) => match.mode == selectedMode)
        .toList(growable: false);
    final stats = StatsService.computeLeaderboard(_players, modeMatches);
    final List<TeamLeaderboardStats> teams = selectedMode == MatchMode.twoVsTwo
        ? StatsService.computeTeamLeaderboard(_players, modeMatches)
        : const <TeamLeaderboardStats>[];
    emit(
      state.copyWith(
        stats: stats,
        teams: teams,
        selectedMode: selectedMode,
        isLoading: false,
      ),
    );
  }

  void selectMode(MatchMode mode) {
    if (state.selectedMode == mode) return;
    _recompute(mode: mode);
  }

  void selectTab(int index) {
    if (index < 0 || index > 1) throw RangeError.range(index, 0, 1);
    if (index != state.selectedTab) emit(state.copyWith(selectedTab: index));
  }

  static MatchMode _defaultMode(List<GameMatch> matches) {
    return matches.any((match) => match.mode == MatchMode.twoVsTwo)
        ? MatchMode.twoVsTwo
        : MatchMode.oneVsOne;
  }

  @override
  Future<void> close() async {
    await _playersSub.cancel();
    await _matchesSub.cancel();
    return super.close();
  }
}
