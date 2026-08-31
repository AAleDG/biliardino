import 'dart:async';
import 'dart:math';

import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_state.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/match_rules.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/match_rules_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NewMatchCubit', () {
    test('excludes archived players even when presence is stale', () async {
      final initial = _players();
      final players = _PlayerRepositoryFake([
        ...initial,
        Player(
          id: 'archived',
          name: 'Archived',
          createdAt: DateTime(2024),
          isPresent: true,
          isArchived: true,
        ),
      ]);
      final cubit = _readyCubit(
        players: players,
        matches: _MatchRepositoryFake(),
        rules: _MatchRulesRepositoryFake(),
      );
      cubit.setTeam('archived', 1);
      players.emit([
        ...initial,
        Player(
          id: 'archived',
          name: 'Archived',
          createdAt: DateTime(2024),
          isPresent: true,
          isArchived: true,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.assignment, isNot(contains('archived')));
      await cubit.close();
      await players.dispose();
    });
    test('persists one immutable snapshot while save is in progress', () async {
      final players = _PlayerRepositoryFake(_players());
      final matches = _MatchRepositoryFake();
      final rules = _MatchRulesRepositoryFake();
      final pendingSave = Completer<void>();
      matches.onSave = (_) => pendingSave.future;
      final cubit = _readyCubit(
        players: players,
        matches: matches,
        rules: rules,
      );

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

    test(
      'defers player invalidation until a successful save is acknowledged',
      () async {
        final initialPlayers = _players();
        final players = _PlayerRepositoryFake(initialPlayers);
        final matches = _MatchRepositoryFake();
        final rules = _MatchRulesRepositoryFake();
        final pendingSave = Completer<void>();
        matches.onSave = (_) => pendingSave.future;
        final cubit = _readyCubit(
          players: players,
          matches: matches,
          rules: rules,
        );

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
      },
    );

    test(
      'retains the active match after a failed save and allows retry',
      () async {
        final players = _PlayerRepositoryFake(_players());
        final matches = _MatchRepositoryFake();
        final rules = _MatchRulesRepositoryFake();
        matches.onSave = (_) => Future<void>.error(StateError('database down'));
        final cubit = _readyCubit(
          players: players,
          matches: matches,
          rules: rules,
        );

        await cubit.save();

        expect(cubit.state.isSaving, isFalse);
        expect(cubit.state.kickedOff, isTrue);
        expect(cubit.state.score1, 1);
        expect(cubit.state.lastVictory, isNull);
        expect(cubit.state.lastFeedback?.kind, NewMatchFeedback.saveFailed);

        matches.onSave = (_) async {};
        await cubit.save();

        expect(matches.saved, hasLength(2));
        expect(cubit.state.lastVictory, isNotNull);

        await cubit.close();
        await players.dispose();
      },
    );

    test(
      'ignores victory acknowledgement when no victory is pending',
      () async {
        final players = _PlayerRepositoryFake(_players());
        final matches = _MatchRepositoryFake();
        final cubit = NewMatchCubit(
          playerRepository: players,
          matchRepository: matches,
          matchRulesRepository: _MatchRulesRepositoryFake(),
        );

        cubit
          ..setTeam('p1', 1)
          ..setTeam('p2', 1);
        final assignment = Map<String, int>.from(cubit.state.assignment);

        cubit.acknowledgeVictory();

        expect(cubit.state.assignment, assignment);
        expect(cubit.state.score1, 0);
        expect(cubit.state.score2, 0);
        expect(cubit.state.kickedOff, isFalse);
        expect(cubit.state.lastVictory, isNull);

        await cubit.close();
        await players.dispose();
      },
    );

    test(
      'clears teams after choosing change teams from victory overlay',
      () async {
        final players = _PlayerRepositoryFake(_players());
        final matches = _MatchRepositoryFake();
        final cubit = _readyCubit(
          players: players,
          matches: matches,
          rules: _MatchRulesRepositoryFake(),
        );

        await cubit.save();
        cubit.changeTeamsAfterVictory();

        expect(cubit.state.lastVictory, isNull);
        expect(cubit.state.assignment, isEmpty);
        expect(cubit.state.kickedOff, isFalse);
        expect(cubit.state.isRivalry, isFalse);

        await cubit.close();
        await players.dispose();
      },
    );

    test(
      'starts a rematch with same teams after victory overlay action',
      () async {
        final players = _PlayerRepositoryFake(_players());
        final matches = _MatchRepositoryFake();
        final cubit = _readyCubit(
          players: players,
          matches: matches,
          rules: _MatchRulesRepositoryFake(),
        );

        await cubit.save();
        final previousAssignment = Map<String, int>.from(
          cubit.state.assignment,
        );
        cubit.rematchAfterVictory();

        expect(cubit.state.lastVictory, isNull);
        expect(cubit.state.assignment, previousAssignment);
        expect(cubit.state.kickedOff, isTrue);
        expect(cubit.state.score1, 0);
        expect(cubit.state.score2, 0);
        expect(cubit.state.scorerIds, isEmpty);

        await cubit.close();
        await players.dispose();
      },
    );

    test(
      'returns to setup when a deferred player invalidates a rematch',
      () async {
        final initialPlayers = _players();
        final players = _PlayerRepositoryFake(initialPlayers);
        final matches = _MatchRepositoryFake();
        final rules = _MatchRulesRepositoryFake();
        final pendingSave = Completer<void>();
        matches.onSave = (_) => pendingSave.future;
        final cubit = _readyCubit(
          players: players,
          matches: matches,
          rules: rules,
        );

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
          cubit.state.lastFeedback?.kind,
          NewMatchFeedback.playersUnavailable,
        );

        await cubit.close();
        await players.dispose();
      },
    );

    test(
      'removes absent players and interrupts an invalidated match',
      () async {
        final initialPlayers = _players();
        final players = _PlayerRepositoryFake(initialPlayers);
        final matches = _MatchRepositoryFake();
        final cubit = _readyCubit(
          players: players,
          matches: matches,
          rules: _MatchRulesRepositoryFake(),
        );

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
      },
    );

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
        matchRulesRepository: _MatchRulesRepositoryFake(),
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

    test(
      'random generation is deterministic and replaces its proposal',
      () async {
        NewMatchCubit buildCubit() => NewMatchCubit(
          playerRepository: _PlayerRepositoryFake(_players()),
          matchRepository: _MatchRepositoryFake(),
          matchRulesRepository: _MatchRulesRepositoryFake(),
          random: Random(42),
        );

        final first = buildCubit();
        final second = buildCubit();

        first.generateRandomTeams();
        second.generateRandomTeams();
        final initial = Map<String, int>.from(first.state.assignment);

        expect(first.state.assignment, second.state.assignment);
        expect(first.state.assignment, hasLength(4));
        expect(first.state.team1, hasLength(2));
        expect(first.state.team2, hasLength(2));
        expect(first.state.teamsValid, isTrue);

        first.generateRandomTeams();
        expect(first.state.assignment, isNot(initial));
        expect(first.state.teamsValid, isTrue);

        await first.close();
        await second.close();
      },
    );

    test(
      'random generation supports 1v1 and selects only present players',
      () async {
        final players = _PlayerRepositoryFake([
          ..._players(),
          Player(
            id: 'p5',
            name: 'Absent',
            createdAt: DateTime(2026),
            isPresent: false,
          ),
          Player(
            id: 'p6',
            name: 'Reserve',
            createdAt: DateTime(2026),
            isPresent: true,
          ),
        ]);
        final cubit = NewMatchCubit(
          playerRepository: players,
          matchRepository: _MatchRepositoryFake(),
          matchRulesRepository: _MatchRulesRepositoryFake(),
          random: Random(7),
        );

        cubit
          ..setMatchMode(MatchMode.oneVsOne)
          ..generateRandomTeams();

        expect(cubit.state.assignment, hasLength(2));
        expect(cubit.state.assignment, isNot(contains('p5')));
        expect(cubit.state.team1, hasLength(1));
        expect(cubit.state.team2, hasLength(1));
        expect(cubit.state.teamsValid, isTrue);

        await cubit.close();
        await players.dispose();
      },
    );

    test(
      'balanced generation minimizes leaderboard point difference',
      () async {
        final matches = _MatchRepositoryFake(
          initialMatches: [
            ..._winsFor('p1', 3),
            ..._winsFor('p2', 2),
            ..._winsFor('p3', 1),
          ],
        );
        final cubit = NewMatchCubit(
          playerRepository: _PlayerRepositoryFake(_players()),
          matchRepository: matches,
          matchRulesRepository: _MatchRulesRepositoryFake(),
          random: Random(3),
        );

        cubit.generateBalancedTeams();

        final team1 = cubit.state.team1.toSet();
        final team2 = cubit.state.team2.toSet();
        expect(
          (team1.containsAll(['p1', 'p4']) &&
                  team2.containsAll(['p2', 'p3'])) ||
              (team2.containsAll(['p1', 'p4']) &&
                  team1.containsAll(['p2', 'p3'])),
          isTrue,
        );
        expect(cubit.state.teamsValid, isTrue);

        await cubit.close();
      },
    );

    test(
      'balanced generation finds the global optimum across eligible players',
      () async {
        final players = _PlayerRepositoryFake(_players().take(3).toList());
        final matches = _MatchRepositoryFake(
          initialMatches: [
            ..._winsFor('p1', 3),
            ..._winsFor('p2', 2),
            ..._winsFor('p3', 2),
          ],
        );
        final cubit = NewMatchCubit(
          playerRepository: players,
          matchRepository: matches,
          matchRulesRepository: _MatchRulesRepositoryFake(),
          random: Random(1),
        );

        cubit
          ..setMatchMode(MatchMode.oneVsOne)
          ..generateBalancedTeams();

        expect(cubit.state.assignment.keys.toSet(), {'p2', 'p3'});
        expect(cubit.state.teamsValid, isTrue);

        await cubit.close();
        await players.dispose();
      },
    );

    test(
      'balanced generation resolves ties and produces a new proposal',
      () async {
        final cubit = NewMatchCubit(
          playerRepository: _PlayerRepositoryFake(_players()),
          matchRepository: _MatchRepositoryFake(),
          matchRulesRepository: _MatchRulesRepositoryFake(),
          random: Random(11),
        );

        cubit.generateBalancedTeams();
        final initial = Map<String, int>.from(cubit.state.assignment);
        cubit.generateBalancedTeams();

        expect(cubit.state.assignment, isNot(initial));
        expect(cubit.state.teamsValid, isTrue);

        await cubit.close();
      },
    );

    test(
      'balanced generation stays responsive with 100 equally ranked players',
      () async {
        final players = _PlayerRepositoryFake(
          List.generate(
            100,
            (index) => Player(
              id: 'large-$index',
              name: 'Large Player $index',
              createdAt: DateTime(2026),
              isPresent: true,
            ),
          ),
        );
        final cubit = NewMatchCubit(
          playerRepository: players,
          matchRepository: _MatchRepositoryFake(),
          matchRulesRepository: _MatchRulesRepositoryFake(),
          random: Random(17),
        );
        final stopwatch = Stopwatch()..start();

        cubit.generateBalancedTeams();
        stopwatch.stop();

        expect(cubit.state.assignment, hasLength(4));
        expect(cubit.state.teamsValid, isTrue);
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));

        await cubit.close();
        await players.dispose();
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    test(
      'generation is ignored when unavailable or match state is locked',
      () async {
        final tooFewPlayers = _PlayerRepositoryFake(
          _players().take(3).toList(),
        );
        final insufficient = NewMatchCubit(
          playerRepository: tooFewPlayers,
          matchRepository: _MatchRepositoryFake(),
          matchRulesRepository: _MatchRulesRepositoryFake(),
          random: Random(1),
        );
        insufficient.generateRandomTeams();
        expect(insufficient.state.assignment, isEmpty);

        final active = _readyCubit(
          players: _PlayerRepositoryFake(_players()),
          matches: _MatchRepositoryFake(),
          rules: _MatchRulesRepositoryFake(),
        );
        final activeAssignment = Map<String, int>.from(active.state.assignment);
        active
          ..generateRandomTeams()
          ..generateBalancedTeams();
        expect(active.state.assignment, activeAssignment);

        await insufficient.close();
        await active.close();
        await tooFewPlayers.dispose();
      },
    );

    test('uses free scoring rules by default', () async {
      final cubit = NewMatchCubit(
        playerRepository: _PlayerRepositoryFake(_players()),
        matchRepository: _MatchRepositoryFake(),
        matchRulesRepository: _MatchRulesRepositoryFake(),
      );

      expect(cubit.state.rules, MatchRules.defaultRules);

      await cubit.close();
    });

    test('persists rule changes before kickoff', () async {
      final rules = _MatchRulesRepositoryFake();
      final cubit = NewMatchCubit(
        playerRepository: _PlayerRepositoryFake(_players()),
        matchRepository: _MatchRepositoryFake(),
        matchRulesRepository: rules,
      );

      await cubit.setRuleMode(MatchRuleMode.firstTo);
      await cubit.setTargetScore(7);
      await cubit.setWinByTwo(true);

      expect(cubit.state.rules.mode, MatchRuleMode.firstTo);
      expect(cubit.state.rules.targetScore, 7);
      expect(cubit.state.rules.winByTwo, isTrue);
      expect(rules.saved, hasLength(3));

      await cubit.close();
    });

    test('ignores rule changes after kickoff', () async {
      final rules = _MatchRulesRepositoryFake();
      final cubit = _readyCubit(
        players: _PlayerRepositoryFake(_players()),
        matches: _MatchRepositoryFake(),
        rules: rules,
      );

      await cubit.setRuleMode(MatchRuleMode.firstTo);
      await cubit.setTargetScore(3);

      expect(cubit.state.rules, MatchRules.defaultRules);
      expect(rules.saved, isEmpty);

      await cubit.close();
    });

    test(
      'requires confirmation before saving a completed first-to match',
      () async {
        final matches = _MatchRepositoryFake();
        final cubit = _readyCubit(
          players: _PlayerRepositoryFake(_players()),
          matches: matches,
          rules: _MatchRulesRepositoryFake(
            initialRules: const MatchRules(
              mode: MatchRuleMode.firstTo,
              targetScore: 2,
              winByTwo: false,
            ),
          ),
        );

        cubit.addGoal(1, 'p2');
        expect(cubit.state.pendingVictory?.winningTeam, 1);

        cubit.addGoal(1, 'p1');
        await cubit.save();

        expect(cubit.state.score1, 2);
        expect(matches.saved, isEmpty);

        await cubit.confirmAndSaveCompletedMatch();

        expect(matches.saved, hasLength(1));
        expect(matches.saved.single.score1, 2);
        expect(cubit.state.lastVictory?.winningTeam, 1);

        await cubit.close();
      },
    );

    test(
      'restores pending victory after a completed match save fails',
      () async {
        final matches = _MatchRepositoryFake();
        matches.onSave = (_) => Future<void>.error(StateError('database down'));
        final cubit = _readyCubit(
          players: _PlayerRepositoryFake(_players()),
          matches: matches,
          rules: _MatchRulesRepositoryFake(
            initialRules: const MatchRules(
              mode: MatchRuleMode.firstTo,
              targetScore: 2,
              winByTwo: false,
            ),
          ),
        );

        cubit.addGoal(1, 'p2');
        await cubit.confirmAndSaveCompletedMatch();

        expect(cubit.state.isSaving, isFalse);
        expect(cubit.state.pendingVictory?.winningTeam, 1);
        expect(cubit.state.pendingVictory?.winnerScore, 2);
        expect(cubit.state.lastFeedback?.kind, NewMatchFeedback.saveFailed);

        matches.onSave = (_) async {};
        await cubit.confirmAndSaveCompletedMatch();

        expect(matches.saved, hasLength(2));
        expect(cubit.state.pendingVictory, isNull);
        expect(cubit.state.lastVictory?.winningTeam, 1);

        await cubit.close();
      },
    );

    test('allows score correction before confirmation', () async {
      final cubit = _readyCubit(
        players: _PlayerRepositoryFake(_players()),
        matches: _MatchRepositoryFake(),
        rules: _MatchRulesRepositoryFake(
          initialRules: const MatchRules(
            mode: MatchRuleMode.firstTo,
            targetScore: 2,
            winByTwo: false,
          ),
        ),
      );

      cubit.addGoal(1, 'p2');
      cubit.correctScoreBeforeConfirmation();
      cubit.removeGoal(1);

      expect(cubit.state.pendingVictory, isNull);
      expect(cubit.state.score1, 1);

      await cubit.close();
    });

    test('blocks kickoff while rule persistence is pending', () async {
      final rules = _MatchRulesRepositoryFake();
      final pendingRuleSave = Completer<void>();
      rules.onSave = (_) => pendingRuleSave.future;
      final cubit = NewMatchCubit(
        playerRepository: _PlayerRepositoryFake(_players()),
        matchRepository: _MatchRepositoryFake(),
        matchRulesRepository: rules,
      );
      cubit
        ..setTeam('p1', 1)
        ..setTeam('p2', 1)
        ..setTeam('p3', 2)
        ..setTeam('p4', 2);

      final ruleSave = cubit.setRuleMode(MatchRuleMode.firstTo);
      expect(cubit.state.isPersistingRules, isTrue);
      expect(cubit.state.rules.mode, MatchRuleMode.firstTo);

      await cubit.setTargetScore(7);
      cubit.kickoff();

      expect(cubit.state.rules.targetScore, 10);
      expect(cubit.state.kickedOff, isFalse);
      expect(rules.saved, hasLength(1));

      pendingRuleSave.completeError(StateError('disk full'));
      await ruleSave;

      expect(cubit.state.isPersistingRules, isFalse);
      expect(cubit.state.rules, MatchRules.defaultRules);
      expect(cubit.state.lastFeedback?.kind, NewMatchFeedback.saveFailed);

      await cubit.close();
    });
  });
}

NewMatchCubit _readyCubit({
  required _PlayerRepositoryFake players,
  required _MatchRepositoryFake matches,
  required _MatchRulesRepositoryFake rules,
}) {
  final cubit = NewMatchCubit(
    playerRepository: players,
    matchRepository: matches,
    matchRulesRepository: rules,
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

class _MatchRulesRepositoryFake implements MatchRulesRepository {
  _MatchRulesRepositoryFake({MatchRules initialRules = MatchRules.defaultRules})
    : _rules = initialRules;

  MatchRules _rules;
  Future<void> Function(MatchRules rules)? onSave;
  final List<MatchRules> saved = [];

  @override
  MatchRules get rules => _rules;

  @override
  Future<void> load() async {}

  @override
  Future<void> save(MatchRules rules) async {
    saved.add(rules);
    await (onSave?.call(rules) ?? Future<void>.value());
    _rules = rules;
  }
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
  _MatchRepositoryFake({List<GameMatch> initialMatches = const []})
    : _matches = List.unmodifiable(initialMatches);

  Future<void> Function(_SavedMatch match)? onSave;
  final List<_SavedMatch> saved = [];
  final List<GameMatch> _matches;

  @override
  List<GameMatch> get matches => _matches;

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
  Stream<List<GameMatch>> watchMatches() => Stream.value(_matches);
}

List<GameMatch> _winsFor(String playerId, int wins) {
  return List.generate(
    wins,
    (index) => GameMatch(
      id: '$playerId-$index',
      playedAt: DateTime(2026, 1, index + 1),
      mode: MatchMode.oneVsOne,
      t1p1: playerId,
      t1p2: '',
      t2p1: 'opponent-$playerId-$index',
      t2p2: '',
      t1Score: 1,
      t2Score: 0,
      winningTeam: 1,
      scorerIds: [playerId],
    ),
  );
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
  Future<void> archivePlayer(Player player) async {}

  @override
  Future<void> reactivatePlayer(Player player) async {}

  @override
  Future<void> dispose() => _controller.close();

  @override
  Future<void> load() async {}

  @override
  Future<void> togglePresent(Player p) async {}
}
