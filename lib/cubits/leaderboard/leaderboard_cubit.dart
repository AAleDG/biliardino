import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/player_repository.dart';
import '../../services/stats_service.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit({
    required PlayerRepository playerRepository,
    required MatchRepository matchRepository,
  })  : _playerRepo = playerRepository,
        _matchRepo = matchRepository,
        super(const LeaderboardState()) {
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
  late final StreamSubscription<List<Player>> _playersSub;
  late final StreamSubscription<List<GameMatch>> _matchesSub;

  List<Player> _players = const [];
  List<GameMatch> _matches = const [];

  void _recompute() {
    final stats = StatsService.computeLeaderboard(_players, _matches);
    emit(state.copyWith(stats: stats, isLoading: false));
  }

  @override
  Future<void> close() async {
    await _playersSub.cancel();
    await _matchesSub.cancel();
    return super.close();
  }
}
