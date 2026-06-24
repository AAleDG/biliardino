import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/player.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/player_repository.dart';
import '../../services/stats_service.dart';
import 'new_match_state.dart';

class NewMatchCubit extends Cubit<NewMatchState> {
  NewMatchCubit({
    required PlayerRepository playerRepository,
    required MatchRepository matchRepository,
  })  : _playerRepo = playerRepository,
        _matchRepo = matchRepository,
        super(const NewMatchState()) {
    emit(state.copyWith(players: _playerRepo.players));
    _playersSub = _playerRepo.watchPlayers().listen((players) {
      emit(state.copyWith(players: players));
    });
  }

  final PlayerRepository _playerRepo;
  final MatchRepository _matchRepo;
  late final StreamSubscription<List<Player>> _playersSub;
  int _signal = 0;

  int _nextSignal() => ++_signal;

  void setTeam(String playerId, int team) {
    if (state.kickedOff) return;
    final current = Map<String, int>.from(state.assignment);
    final isSame = current[playerId] == team;
    current[playerId] = isSame ? 0 : team;
    emit(state.copyWith(assignment: current));
  }

  void kickoff() {
    if (!state.teamsValid || state.kickedOff) return;
    HapticFeedback.mediumImpact();
    emit(state.copyWith(kickedOff: true, score1: 0, score2: 0));
  }

  void addGoal(int team) {
    if (!state.kickedOff) return;
    if (team == 1) {
      emit(state.copyWith(
        score1: state.score1 + 1,
        lastGoal: GoalEvent(team: 1, signalId: _nextSignal()),
      ));
    } else {
      emit(state.copyWith(
        score2: state.score2 + 1,
        lastGoal: GoalEvent(team: 2, signalId: _nextSignal()),
      ));
    }
  }

  void removeGoal(int team) {
    if (!state.kickedOff) return;
    if (team == 1 && state.score1 > 0) {
      HapticFeedback.selectionClick();
      emit(state.copyWith(score1: state.score1 - 1));
    } else if (team == 2 && state.score2 > 0) {
      HapticFeedback.selectionClick();
      emit(state.copyWith(score2: state.score2 - 1));
    }
  }

  void setScore(int team, int value) {
    if (!state.kickedOff || value < 0) return;
    if (team == 1) {
      emit(state.copyWith(score1: value));
    } else {
      emit(state.copyWith(score2: value));
    }
  }

  void resetScore() {
    if (!state.kickedOff) return;
    emit(state.copyWith(score1: 0, score2: 0));
  }

  void abortMatch() {
    emit(state.copyWith(kickedOff: false, score1: 0, score2: 0));
  }

  Future<void> save() async {
    if (!state.kickedOff || !state.teamsValid) return;
    if (state.score1 == state.score2) {
      emit(state.copyWith(
        lastFeedback: FeedbackEvent(
          kind: NewMatchFeedback.noWinner,
          signalId: _nextSignal(),
        ),
      ));
      return;
    }
    if (state.score1 == 0 && state.score2 == 0) {
      emit(state.copyWith(
        lastFeedback: FeedbackEvent(
          kind: NewMatchFeedback.noGoals,
          signalId: _nextSignal(),
        ),
      ));
      return;
    }

    final team1 = state.team1;
    final team2 = state.team2;
    await _matchRepo.addMatch(
      team1: team1,
      team2: team2,
      score1: state.score1,
      score2: state.score2,
    );

    final t1Won = state.score1 > state.score2;
    final winningTeam = t1Won ? 1 : 2;
    final winnerIds = t1Won ? team1 : team2;
    final winnerNames =
        winnerIds.map((id) => StatsService.playerName(state.players, id)).toList();
    final winnerScore = t1Won ? state.score1 : state.score2;
    final loserScore = t1Won ? state.score2 : state.score1;

    emit(state.copyWith(
      lastVictory: VictoryEvent(
        winningTeam: winningTeam,
        winnerIds: winnerIds,
        winnerNames: winnerNames,
        winnerScore: winnerScore,
        loserScore: loserScore,
        signalId: _nextSignal(),
      ),
    ));
  }

  void acknowledgeVictory() {
    emit(state.copyWith(
      assignment: const {},
      score1: 0,
      score2: 0,
      kickedOff: false,
    ));
  }

  @override
  Future<void> close() async {
    await _playersSub.cancel();
    return super.close();
  }
}
