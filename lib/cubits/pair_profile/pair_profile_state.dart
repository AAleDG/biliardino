import 'package:equatable/equatable.dart';

import '../../models/pair_profile_stats.dart';
import '../../models/player.dart';

class PairProfileState extends Equatable {
  PairProfileState({required List<Player> players, required this.profile})
    : players = List.unmodifiable(players);

  final List<Player> players;
  final PairProfileStats? profile;

  @override
  List<Object?> get props => [players, profile];
}
