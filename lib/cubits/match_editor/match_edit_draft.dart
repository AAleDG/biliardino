import 'package:equatable/equatable.dart';
import '../../models/game_match.dart';

/// Ordered, compact attribution: editing a large score does not allocate goals.
class GoalRun extends Equatable {
  const GoalRun(this.playerId, this.count);
  final String playerId;
  final int count;
  @override
  List<Object> get props => [playerId, count];
}

class MatchEditDraft extends Equatable {
  MatchEditDraft._({
    required this.original,
    required this.mode,
    required this.playedAt,
    required this.isRivalry,
    required List<String> team1,
    required List<String> team2,
    required this.score1,
    required this.score2,
    required List<GoalRun> goals,
  }) : team1 = List.unmodifiable(team1),
       team2 = List.unmodifiable(team2),
       goals = List.unmodifiable(goals);

  factory MatchEditDraft.fromMatch(GameMatch match) {
    final runs = <GoalRun>[];
    for (final id in match.scorerIds) {
      if (runs.isNotEmpty && runs.last.playerId == id) {
        runs[runs.length - 1] = GoalRun(id, runs.last.count + 1);
      } else {
        runs.add(GoalRun(id, 1));
      }
    }
    return MatchEditDraft._(
      original: match,
      mode: match.mode,
      playedAt: match.playedAt,
      isRivalry: match.isRivalry,
      team1: match.team1,
      team2: match.team2,
      score1: match.t1Score,
      score2: match.t2Score,
      goals: runs,
    );
  }

  final GameMatch original;
  final MatchMode mode;
  final DateTime playedAt;
  final bool isRivalry;
  final List<String> team1, team2;
  final int score1, score2;
  final List<GoalRun> goals;

  List<String> team(int number) => number == 1 ? team1 : team2;
  int score(int number) => number == 1 ? score1 : score2;
  int goalsFor(String id) =>
      goals.where((g) => g.playerId == id).fold(0, (sum, g) => sum + g.count);
  int assigned(int number) =>
      team(number).fold(0, (sum, id) => sum + goalsFor(id));
  int missing(int number) => score(number) - assigned(number);
  bool get isDirty => this != MatchEditDraft.fromMatch(original);

  MatchEditDraft _copy({
    MatchMode? mode,
    DateTime? playedAt,
    bool? isRivalry,
    List<String>? team1,
    List<String>? team2,
    int? score1,
    int? score2,
    List<GoalRun>? goals,
  }) => MatchEditDraft._(
    original: original,
    mode: mode ?? this.mode,
    playedAt: playedAt ?? this.playedAt,
    isRivalry: isRivalry ?? this.isRivalry,
    team1: team1 ?? this.team1,
    team2: team2 ?? this.team2,
    score1: score1 ?? this.score1,
    score2: score2 ?? this.score2,
    goals: goals ?? this.goals,
  );

  MatchEditDraft withDate(DateTime date) => _copy(
    playedAt: DateTime(
      date.year,
      date.month,
      date.day,
      playedAt.hour,
      playedAt.minute,
      playedAt.second,
      playedAt.millisecond,
      playedAt.microsecond,
    ),
  );
  MatchEditDraft withTime(int hour, int minute) => _copy(
    playedAt: DateTime(
      playedAt.year,
      playedAt.month,
      playedAt.day,
      hour,
      minute,
      playedAt.second,
      playedAt.millisecond,
      playedAt.microsecond,
    ),
  );
  MatchEditDraft withScore(int number, int value) =>
      number == 1 ? _copy(score1: value) : _copy(score2: value);
  MatchEditDraft withRivalry(bool value) =>
      mode == MatchMode.twoVsTwo && value && !isRivalry
      ? this
      : _copy(isRivalry: value);

  MatchEditDraft withMode(MatchMode value) {
    final first = team1.take(value.teamSize).toList();
    final second = team2.take(value.teamSize).toList();
    final retained = {...first, ...second};
    return _copy(
      mode: value,
      team1: first,
      team2: second,
      goals: goals.where((g) => retained.contains(g.playerId)).toList(),
    );
  }

  MatchEditDraft replacePlayer(int number, int slot, String id) {
    final current = team(number);
    if (id.trim().isEmpty || slot < 0 || slot >= mode.teamSize) return this;
    if ([...team1, ...team2].contains(id)) return this;
    final updated = [...current];
    while (updated.length <= slot) {
      updated.add('');
    }
    final old = updated[slot];
    updated[slot] = id;
    final retained = goals.where((g) => g.playerId != old).toList();
    return number == 1
        ? _copy(team1: updated, goals: retained)
        : _copy(team2: updated, goals: retained);
  }

  MatchEditDraft changeGoals(int number, String id, int delta) {
    if (!team(number).contains(id) || (delta != 1 && delta != -1)) return this;
    if (delta > 0) {
      if (missing(number) <= 0) return this;
      return _append(id, 1);
    }
    final index = goals.lastIndexWhere((g) => g.playerId == id);
    if (index < 0) return this;
    final updated = [...goals];
    final run = updated[index];
    if (run.count == 1) {
      updated.removeAt(index);
    } else {
      updated[index] = GoalRun(id, run.count - 1);
    }
    return _copy(goals: updated);
  }

  MatchEditDraft confirmSingleScorer(int number) {
    final ids = team(number);
    if (mode != MatchMode.oneVsOne ||
        ids.length != 1 ||
        ids.single.isEmpty ||
        missing(number) <= 0) {
      return this;
    }
    return _append(ids.single, missing(number));
  }

  MatchEditDraft _append(String id, int count) {
    final updated = [...goals];
    if (updated.isNotEmpty && updated.last.playerId == id) {
      updated[updated.length - 1] = GoalRun(id, updated.last.count + count);
    } else {
      updated.add(GoalRun(id, count));
    }
    return _copy(goals: updated);
  }

  String? get validationError {
    if (score1 < 0 || score2 < 0) return 'Inserisci punteggi validi.';
    if (score1 == score2) return 'La partita deve avere un vincitore.';
    if (team1.length != mode.teamSize ||
        team2.length != mode.teamSize ||
        [...team1, ...team2].any((id) => id.isEmpty)) {
      return 'Completa entrambe le squadre.';
    }
    if ({...team1, ...team2}.length != mode.teamSize * 2) {
      return 'Ogni giocatore può stare in una sola squadra.';
    }
    if (goals.any(
      (g) => !team1.contains(g.playerId) && !team2.contains(g.playerId),
    )) {
      return 'Ogni marcatore deve appartenere alla propria squadra.';
    }
    if (assigned(1) > score1 || assigned(2) > score2) {
      return 'Rimuovi i gol assegnati in eccesso prima di salvare.';
    }
    if (missing(1) != 0 || missing(2) != 0) {
      return 'Assegna tutti i marcatori prima di salvare.';
    }
    return null;
  }

  GameMatch toMatch() {
    if (validationError != null) throw StateError(validationError!);
    return original.copyWith(
      mode: mode,
      playedAt: playedAt,
      isRivalry: isRivalry,
      t1p1: team1[0],
      t1p2: mode.teamSize == 2 ? team1[1] : '',
      t2p1: team2[0],
      t2p2: mode.teamSize == 2 ? team2[1] : '',
      t1Score: score1,
      t2Score: score2,
      winningTeam: score1 > score2 ? 1 : 2,
      scorerIds: List.unmodifiable(
        goals.expand((g) => Iterable.generate(g.count, (_) => g.playerId)),
      ),
    );
  }

  @override
  List<Object> get props => [
    mode,
    playedAt,
    isRivalry,
    team1,
    team2,
    score1,
    score2,
    goals,
  ];
}
