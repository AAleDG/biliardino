import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../models/player_stats.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/player_repository.dart';
import '../../services/stats_service.dart';
import 'player_profile_state.dart';

class PlayerProfileCubit extends Cubit<PlayerProfileState> {
  PlayerProfileCubit({
    required this.playerId,
    required PlayerRepository playerRepository,
    required MatchRepository matchRepository,
  }) : _players = playerRepository.players,
       _matches = matchRepository.matches,
       super(
         _derive(playerId, playerRepository.players, matchRepository.matches),
       ) {
    _playersSub = playerRepository.watchPlayers().listen((players) {
      if (identical(players, _players)) return;
      _players = players;
      _recompute();
    });
    _matchesSub = matchRepository.watchMatches().listen((matches) {
      if (identical(matches, _matches)) return;
      _matches = matches;
      _recompute();
    });
  }

  final String playerId;
  List<Player> _players;
  List<GameMatch> _matches;
  late final StreamSubscription<List<Player>> _playersSub;
  late final StreamSubscription<List<GameMatch>> _matchesSub;

  void _recompute() => emit(_derive(playerId, _players, _matches));

  static PlayerProfileState _derive(
    String playerId,
    List<Player> players,
    List<GameMatch> matches,
  ) {
    PlayerStats? stats;
    for (final candidate in StatsService.computeLeaderboard(players, matches)) {
      if (candidate.player.id == playerId) {
        stats = candidate;
        break;
      }
    }
    final history = StatsService.playerHistory(matches, playerId);
    return PlayerProfileState(
      players: players,
      stats: stats,
      profile: history.profile,
      personalMatches: history.matches,
    );
  }

  @override
  Future<void> close() async {
    await Future.wait([_playersSub.cancel(), _matchesSub.cancel()]);
    await super.close();
  }
}
