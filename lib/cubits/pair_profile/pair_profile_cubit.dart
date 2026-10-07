import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/player_repository.dart';
import '../../services/stats_service.dart';
import 'pair_profile_state.dart';

class PairProfileCubit extends Cubit<PairProfileState> {
  PairProfileCubit({
    required this.pairId,
    required PlayerRepository playerRepository,
    required MatchRepository matchRepository,
  }) : _players = playerRepository.players,
       _matches = matchRepository.matches,
       super(
         _derive(pairId, playerRepository.players, matchRepository.matches),
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

  final String pairId;
  List<Player> _players;
  List<GameMatch> _matches;
  late final StreamSubscription<List<Player>> _playersSub;
  late final StreamSubscription<List<GameMatch>> _matchesSub;

  void _recompute() => emit(_derive(pairId, _players, _matches));

  static PairProfileState _derive(
    String pairId,
    List<Player> players,
    List<GameMatch> matches,
  ) => PairProfileState(
    players: List.unmodifiable(players),
    profile: StatsService.computePairProfile(players, matches, pairId),
  );

  @override
  Future<void> close() async {
    await Future.wait([_playersSub.cancel(), _matchesSub.cancel()]);
    await super.close();
  }
}
