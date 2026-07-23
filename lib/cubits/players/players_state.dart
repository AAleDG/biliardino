import 'package:equatable/equatable.dart';

import '../../models/player.dart';

enum PlayersFeedback { addFailed, presenceUpdateFailed }

class PlayersState extends Equatable {
  final List<Player> players;
  final bool isLoading;
  final bool isMutating;
  final PlayersFeedback? feedback;

  const PlayersState({
    this.players = const [],
    this.isLoading = true,
    this.isMutating = false,
    this.feedback,
  });

  PlayersState copyWith({
    List<Player>? players,
    bool? isLoading,
    bool? isMutating,
    PlayersFeedback? feedback,
    bool clearFeedback = false,
  }) {
    return PlayersState(
      players: players ?? this.players,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      feedback: clearFeedback ? null : feedback ?? this.feedback,
    );
  }

  List<Player> get present => players.where((p) => p.isPresent).toList();

  @override
  List<Object?> get props => [players, isLoading, isMutating, feedback];
}
