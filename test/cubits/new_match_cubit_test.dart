import 'dart:async';

import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_state.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NewMatchCubit', () {
    test('persists one immutable snapshot while save is in progress', () async {
      final players = _PlayerRepositoryFake(_players());
      final matches = _MatchRepositoryFake();
      final pendingSave = Completer<void>();
      matches.onSave = (_) => pendingSave.future;
      final cubit = _readyCubit(players: players, matches: matches);

      final firstSave = cubit.save();
      expect(cubit.state.isSaving, isTrue);

      cubit.addGoal(2, 'p3');
      cubit.removeGoal(1);
      final secondSave = cubit.save();

      expect(matches.saved, hasLength(1));
      expect(matches.saved.single.score1, 1);
      expect(matches.saved.single.score2, 0);
      expect(cubit.state.score1, 1);
      expect(cubit.state.score2, 0);

      pendingSave.complete();
      await Future.wait([firstSave, secondSave]);

      expect(cubit.state.isSaving, isFalse);
      expect(cubit.state.lastVictory?.winnerScore, 1);
      expect(cubit.state.lastVictory?.loserScore, 0);
      expect(cubit.state.lastVictory?.winnerIds, ['p1', 'p2']);

      await cubit.close();
      await players.dispose();
    });

    test('defers player invalidation until a successful save is acknowledged',
        () async {
      final initialPlayers = _players();
      final players = _PlayerRepositoryFake(initialPlayers);
      final matches = _MatchRepositoryFake();
      final pendingSave = Completer<void>();
      matches.onSave = (_) => pendingSave.future;
      final cubit = _readyCubit(players: players, matches: matches);

      final save = cubit.save();
      players.emit([
        initialPlayers.first.copyWith(isPresent: false),
        ...initialPlayers.skip(1),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isSaving, isTrue);
      expect(cubit.state.kickedOff, isTrue);
      expect(cubit.state.teamsValid, isTrue);
      expect(cubit.state.lastFeedback, isNull);

      pendingSave.complete();
      await save;

      expect(cubit.state.lastVictory, isNotNull);
      expect(cubit.state.lastFeedback, isNull);
      expect(cubit.state.players.first.isPresent, isTrue);

      cubit.acknowledgeVictory();

      expect(cubit.state.lastVictory, isNull);
      expect(cubit.state.assignment, isEmpty);
      expect(cubit.state.players.first.isPresent, isFalse);

      await cubit.close();
      await players.dispose();
    });

    test('retains the active match after a failed save and allows retry',
        () async {
      final players = _PlayerRepositoryFake(_players());
      final matches = _MatchRepositoryFake();
      matches.onSave = (_) => Future<void>.error(StateError('database down'));
      final cubit = _readyCubit(players: players, matches: matches);

      await cubit.save();

      expect(cubit.state.isSaving, isFalse);
      expect(cubit.state.kickedOff, isTrue);
      expect(cubit.state.score1, 1);
      expect(cubit.state.lastVictory, isNull);
      expect(
        cubit.state.lastFeedback?.kind,
        NewMatchFeedback.saveFailed,
      );

      matches.onSave = (_) async {};
      await cubit.save();

      expect(matches.saved, hasLength(2));
      expect(cubit.state.lastVictory, isNotNull);

      await cubit.close();
      await players.dispose();
    });

    test('clears teams after choosing change teams from victory overlay',
        () async {
      final players = _PlayerRepositoryFake(_players());
      final matches = _MatchRepositoryFake();
      final cubit = _readyCubit(players: players, matches: matches);

      await cubit.save();
      cubit.changeTeamsAfterVictory();

      expect(cubit.state.lastVictory, isNull);
      expect(cubit.state.assignment, isEmpty);
      expect(cubit.state.kickedOff, isFalse);
      expect(cubit.state.isRivalry, isFalse);

      await cubit.close();
      await players.dispose();
    });

    test('starts a rematch with same teams after victory overlay action',
        () async {
      final players = _PlayerRepositoryFake(_players());
      final matches = _MatchRepositoryFake();
      final cubit = _readyCubit(players: players, matches: matches);

      await cubit.save();
      final previousAssignment = Map<String, int>.from(cubit.state.assignment);
      cubit.rematchAfterVictory();

      expect(cubit.state.lastVictory, isNull);
      expect(cubit.state.assignment, previousAssignment);
      expect(cubit.state.kickedOff, isTrue);
      expect(cubit.state.score1, 0);
      expect(cubit.state.score2, 0);
      expect(cubit.state.scorerIds, isEmpty);

      await cubit.close();
      await players.dispose();
    });

    test('returns to setup when a deferred player invalidates a rematch',
        () async {
      final initialPlayers = _players();
      final players = _PlayerRepositoryFake(initialPlayers);
      final matches = _MatchRepositoryFake();
      final pendingSave = Completer<void>();
      matches.onSave = (_) => pendingSave.future;
      final cubit = _readyCubit(players: players, matches: matches);

      final save = cubit.save();
      players.emit([
        initialPlayers.first.copyWith(isPresent: false),
        ...initialPlayers.skip(1),
      ]);
      await Future<void>.delayed(Duration.zero);
      pendingSave.complete();
      await save;

      cubit.rematchAfterVictory();

      expect(cubit.state.lastVictory, isNull);
      expect(cubit.state.assignment, isNot(contains('p1')));
      expect(cubit.state.kickedOff, isFalse);
      expect(cubit.state.teamsValid, isFalse);
      expect(
          cubit.state.lastFeedback?.kind, NewMatchFeedback.playersUnavailable);

      await cubit.close();
      await players.dispose();
    });

    test('removes absent players and interrupts an invalidated match',
        () async {
      final initialPlayers = _players();
      final players = _PlayerRepositoryFake(initialPlayers);
      final matches = _MatchRepositoryFake();
      final cubit = _readyCubit(players: players, matches: matches);

      players.emit([
        initialPlayers.first.copyWith(isPresent: false),
        ...initialPlayers.skip(1),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.assignment, isNot(contains('p1')));
      expect(cubit.state.teamsValid, isFalse);
      expect(cubit.state.kickedOff, isFalse);
      expect(cubit.state.score1, 0);
      expect(
        cubit.state.lastFeedback?.kind,
        NewMatchFeedback.playersUnavailable,
      );

      await cubit.close();
      await players.dispose();
    });

    test('rejects non-present players and overfilled teams', () async {
      final players = _PlayerRepositoryFake([
        ..._players(),
        Player(
          id: 'p5',
          name: 'Player 5',
          createdAt: DateTime(2026),
          isPresent: false,
        ),
      ]);
      final matches = _MatchRepositoryFake();
      final cubit = NewMatchCubit(
        playerRepository: players,
        matchRepository: matches,
      );

      cubit.setTeam('p1', 1);
      cubit.setTeam('p2', 1);
      cubit.setTeam('p3', 1);
      cubit.setTeam('p5', 2);

      expect(cubit.state.team1, ['p1', 'p2']);
      expect(cubit.state.assignment, isNot(contains('p3')));
      expect(cubit.state.assignment, isNot(contains('p5')));

      await cubit.close();
      await players.dispose();
    });
  });
}

NewMatchCubit _readyCubit({
  required _PlayerRepositoryFake players,
  required _MatchRepositoryFake matches,
}) {
  final cubit = NewMatchCubit(
    playerRepository: players,
    matchRepository: matches,
  );
  cubit
    ..setTeam('p1', 1)
    ..setTeam('p2', 1)
    ..setTeam('p3', 2)
    ..setTeam('p4', 2)
    ..kickoff()
    ..addGoal(1, 'p1');
  return cubit;
}

List<Player> _players() {
  return List.generate(
    4,
    (index) => Player(
      id: 'p${index + 1}',
      name: 'Player ${index + 1}',
      createdAt: DateTime(2026),
      isPresent: true,
    ),
  );
}

class _SavedMatch {
  const _SavedMatch({
    required this.mode,
    required this.isRivalry,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.scorerIds,
  });

  final MatchMode mode;
  final bool isRivalry;
  final List<String> team1;
  final List<String> team2;
  final int score1;
  final int score2;
  final List<String> scorerIds;
}

class _MatchRepositoryFake implements MatchRepository {
  Future<void> Function(_SavedMatch match)? onSave;
  final List<_SavedMatch> saved = [];

  @override
  List<GameMatch> get matches => const [];

  @override
  Future<void> addMatch({
    required MatchMode mode,
    required bool isRivalry,
    required List<String> team1,
    required List<String> team2,
    required int score1,
    required int score2,
    required List<String> scorerIds,
  }) {
    final match = _SavedMatch(
      mode: mode,
      isRivalry: isRivalry,
      team1: List.unmodifiable(team1),
      team2: List.unmodifiable(team2),
      score1: score1,
      score2: score2,
      scorerIds: List.unmodifiable(scorerIds),
    );
    saved.add(match);
    return onSave?.call(match) ?? Future.value();
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load() async {}

  @override
  Future<void> updateMatch(GameMatch match) async {}

  @override
  Future<void> deleteMatch(String id) async {}

  @override
  Stream<List<GameMatch>> watchMatches() => const Stream.empty();
}

class _PlayerRepositoryFake implements PlayerRepository {
  _PlayerRepositoryFake(List<Player> players)
      : _players = List.unmodifiable(players);

  final StreamController<List<Player>> _controller =
      StreamController<List<Player>>.broadcast();
  List<Player> _players;

  @override
  List<Player> get players => _players;

  void emit(List<Player> players) {
    _players = List.unmodifiable(players);
    _controller.add(_players);
  }

  @override
  Stream<List<Player>> watchPlayers() async* {
    yield _players;
    yield* _controller.stream;
  }

  @override
  Future<void> addPlayer(String name) async {}

  @override
  Future<void> renamePlayer(Player player, String name) async {}

  @override
  Future<void> dispose() => _controller.close();

  @override
  Future<void> load() async {}

  @override
  Future<void> togglePresent(Player p) async {}
}
