import 'package:equatable/equatable.dart';

import '../../models/player.dart';

class PlayersState extends Equatable {
  final List<Player> players;
  final bool isLoading;

  const PlayersState({
    this.players = const [],
    this.isLoading = true,
  });

  PlayersState copyWith({List<Player>? players, bool? isLoading}) {
    return PlayersState(
      players: players ?? this.players,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Player> get present => players.where((p) => p.isPresent).toList();

  @override
  List<Object?> get props => [players, isLoading];
}
