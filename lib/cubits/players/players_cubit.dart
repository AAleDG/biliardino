import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/player.dart';
import '../../repositories/player_repository.dart';
import 'players_state.dart';

class PlayersCubit extends Cubit<PlayersState> {
  PlayersCubit(this._repo) : super(const PlayersState()) {
    _subscription = _repo.watchPlayers().listen((players) {
      emit(state.copyWith(
        players: players,
        isLoading: false,
      ));
    });
  }

  final PlayerRepository _repo;
  late final StreamSubscription<List<Player>> _subscription;

  Future<bool> addPlayer(String name) {
    return _mutate(
      () => _repo.addPlayer(name),
      failureFeedback: PlayersFeedback.addFailed,
    );
  }

  Future<bool> togglePresent(Player p) {
    return _mutate(
      () => _repo.togglePresent(p),
      failureFeedback: PlayersFeedback.presenceUpdateFailed,
    );
  }

  Future<bool> _mutate(
    Future<void> Function() operation, {
    required PlayersFeedback failureFeedback,
  }) async {
    if (state.isMutating) return false;
    emit(state.copyWith(isMutating: true, clearFeedback: true));
    try {
      await operation();
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          isMutating: false,
          feedback: failureFeedback,
        ));
      }
      return false;
    }
    if (!isClosed) {
      emit(state.copyWith(isMutating: false));
    }
    return true;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
