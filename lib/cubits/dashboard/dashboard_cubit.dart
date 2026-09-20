import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/player_repository.dart';
import '../../services/stats_service.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required PlayerRepository playerRepository,
    required MatchRepository matchRepository,
  }) : _playerRepo = playerRepository,
       _matchRepo = matchRepository,
       super(const DashboardState()) {
    _players = _playerRepo.players;
    _matches = _matchRepo.matches;
    _recompute();
    _playersSubscription = _playerRepo.watchPlayers().listen((players) {
      if (identical(players, _players)) return;
      _players = players;
      _recompute();
    });
    _matchesSubscription = _matchRepo.watchMatches().listen((matches) {
      if (identical(matches, _matches)) return;
      _matches = matches;
      _recompute();
    });
  }

  final PlayerRepository _playerRepo;
  final MatchRepository _matchRepo;
  late final StreamSubscription<List<Player>> _playersSubscription;
  late final StreamSubscription<List<GameMatch>> _matchesSubscription;

  List<Player> _players = const [];
  List<GameMatch> _matches = const [];

  void _recompute() {
    final recentMatches = StatsService.sortedByMostRecent(_matches)
        .take(5)
        .map(
          (match) => DashboardMatchSummary(
            match: match,
            teamOneName: _teamName(match.team1),
            teamTwoName: _teamName(match.team2),
          ),
        )
        .toList(growable: false);
    final ranking = StatsService.computeLeaderboard(
      _players,
      _matches,
    ).where((stats) => stats.games > 0).take(4).toList(growable: false);
    emit(
      DashboardState(
        recentMatches: List.unmodifiable(recentMatches),
        ranking: List.unmodifiable(ranking),
        isLoading: false,
      ),
    );
  }

  String _teamName(List<String> playerIds) {
    return playerIds
        .map((id) => StatsService.playerName(_players, id))
        .join(' · ');
  }

  @override
  Future<void> close() async {
    await _playersSubscription.cancel();
    await _matchesSubscription.cancel();
    return super.close();
  }
}
