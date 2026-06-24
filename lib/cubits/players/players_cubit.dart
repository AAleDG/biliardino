import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/player.dart';
import '../../repositories/player_repository.dart';
import 'players_state.dart';

class PlayersCubit extends Cubit<PlayersState> {
  PlayersCubit(this._repo) : super(const PlayersState()) {
    _subscription = _repo.watchPlayers().listen((players) {
      emit(state.copyWith(players: players, isLoading: false));
    });
  }

  final PlayerRepository _repo;
  late final StreamSubscription<List<Player>> _subscription;

  Future<void> addPlayer(String name) => _repo.addPlayer(name);

  Future<void> togglePresent(Player p) => _repo.togglePresent(p);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
