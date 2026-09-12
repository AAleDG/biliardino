import 'package:biliardino/cubits/player_profile/player_profile_cubit.dart';
import 'package:biliardino/cubits/player_profile/player_profile_state.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_database.dart';

Player _player(String id, String name) =>
    Player(id: id, name: name, isPresent: true, createdAt: DateTime(2026));

GameMatch _match({String id = 'm1', int day = 1, bool won = true}) => GameMatch(
  id: id,
  playedAt: DateTime(2026, 1, day),
  mode: MatchMode.twoVsTwo,
  t1p1: 'a',
  t1p2: 'b',
  t2p1: 'c',
  t2p2: 'd',
  t1Score: won ? 1 : 2,
  t2Score: won ? 2 : 1,
  winningTeam: won ? 2 : 1,
  scorerIds: won ? ['a', 'c', 'd'] : ['a', 'b', 'c'],
);

class _Fixture {
  _Fixture({List<GameMatch>? matches, this.playerId = 'c'}) {
    db = FakeDatabaseHelper(
      players: [
        _player('a', 'Andrea'),
        _player('b', 'Luca'),
        _player('c', 'Marco'),
        _player('d', 'Paolo'),
      ],
      matches: matches ?? [_match()],
    );
    players = PlayerRepository(db);
    repository = MatchRepository(db);
  }

  final String playerId;
  late final FakeDatabaseHelper db;
  late final PlayerRepository players;
  late final MatchRepository repository;
  late final PlayerProfileCubit cubit;

  Future<void> load() async {
    await players.load();
    await repository.load();
    cubit = PlayerProfileCubit(
      playerId: playerId,
      playerRepository: players,
      matchRepository: repository,
    );
    await Future<void>.delayed(Duration.zero);
    addTearDown(() async {
      if (!cubit.isClosed) await cubit.close();
      await players.dispose();
      await repository.dispose();
    });
  }

  Future<PlayerProfileState> update(Future<void> Function() mutation) async {
    final next = cubit.stream.first;
    await mutation();
    return next;
  }
}

void main() {
  test(
    'initial snapshot uses real team-two stats and preserves both ties',
    () async {
      final f = _Fixture();
      await f.load();
      final s = f.cubit.state;
      expect(s.player!.name, 'Marco');
      expect(s.stats!.points, 3);
      expect(s.stats!.games, 1);
      expect(s.stats!.wins, 1);
      expect(s.stats!.losses, 0);
      expect(s.stats!.goalsScored, 1);
      expect(s.stats!.winRate, 1);
      expect(s.stats!.currentWinStreak, 1);
      expect(s.profile.recentResults, [true]);
      expect(s.profile.mostFrequentTeammate!.playerIds, ['d']);
      expect(s.profile.mostPlayedOpponent!.playerIds, ['a', 'b']);
      expect(s.profile.headToHead.map((item) => item.opponentId), ['a', 'b']);
      expect(
        s.profile.headToHead.every(
          (item) => item.wins == 1 && item.losses == 0,
        ),
        isTrue,
      );
      expect(s.personalMatches.single.t1Score, 1);
      expect(s.personalMatches.single.t2Score, 2);
    },
  );

  test(
    'missing player and existing player without games remain distinct',
    () async {
      final absent = _Fixture(playerId: 'unknown', matches: []);
      final empty = _Fixture(matches: []);
      await absent.load();
      await empty.load();
      expect(absent.cubit.state.player, isNull);
      final s = empty.cubit.state;
      expect(s.player!.name, 'Marco');
      expect(s.stats!.games, 0);
      expect(s.stats!.badges, isEmpty);
      expect(s.profile.recentResults, isEmpty);
      expect(s.profile.mostFrequentTeammate, isNull);
      expect(s.profile.headToHead, isEmpty);
      expect(s.personalMatches, isEmpty);
    },
  );

  test(
    'rename, presence, archive and related names emit without metric changes',
    () async {
      final f = _Fixture();
      await f.load();
      var s = await f.update(
        () => f.players.renamePlayer(f.cubit.state.player!, 'Mario'),
      );
      expect(s.player!.name, 'Mario');
      s = await f.update(() => f.players.togglePresent(f.cubit.state.player!));
      expect(s.player!.isPresent, isFalse);
      s = await f.update(() => f.players.archivePlayer(f.cubit.state.player!));
      expect(s.player!.isArchived, isTrue);
      expect(s.stats!.points, 3);
      s = await f.update(
        () => f.players.reactivatePlayer(f.cubit.state.player!),
      );
      expect(s.player!.isArchived, isFalse);
      s = await f.update(
        () => f.players.renamePlayer(
          f.players.players.firstWhere((p) => p.id == 'd'),
          'Paola',
        ),
      );
      expect(s.players.firstWhere((p) => p.id == 'd').name, 'Paola');
      expect(s.profile.mostFrequentTeammate!.playerIds, ['d']);
    },
  );

  test(
    'match add, correction, delete and refresh recompute all derived sections',
    () async {
      final f = _Fixture(matches: []);
      await f.load();
      var s = await f.update(
        () => f.repository.addMatch(
          mode: MatchMode.twoVsTwo,
          isRivalry: false,
          team1: ['a', 'b'],
          team2: ['c', 'd'],
          score1: 1,
          score2: 2,
          scorerIds: ['a', 'c', 'd'],
        ),
      );
      expect(s.stats!.wins, 1);
      expect(s.profile.recentResults, [true]);
      final id = s.personalMatches.single.id;
      s = await f.update(
        () => f.repository.updateMatch(_match(id: id, won: false)),
      );
      expect(s.stats!.points, 0);
      expect(s.stats!.losses, 1);
      expect(s.profile.recentResults, [false]);
      expect(s.profile.headToHead.every((h) => h.losses == 1), isTrue);
      s = await f.update(() => f.repository.deleteMatch(id));
      expect(s.personalMatches, isEmpty);
      expect(s.stats!.games, 0);
      f.db.matches.add(_match());
      s = await f.update(f.repository.load);
      expect(s.stats!.points, 3);
      f.db.players.removeWhere((p) => p.id == 'c');
      s = await f.update(f.players.load);
      expect(s.player, isNull);
    },
  );

  test(
    'recent form caps at five; complete history and legacy scorer absence survive',
    () async {
      final f = _Fixture(
        matches: [
          for (var day = 1; day <= 7; day++)
            _match(id: 'm$day', day: day, won: day.isOdd),
          _match(id: 'legacy', day: 8).copyWith(scorerIds: []),
        ],
      );
      await f.load();
      final s = f.cubit.state;
      expect(s.personalMatches.map((m) => m.id), [
        'legacy',
        'm7',
        'm6',
        'm5',
        'm4',
        'm3',
        'm2',
        'm1',
      ]);
      expect(s.profile.recentResults, [true, true, false, true, false]);
      expect(s.stats!.currentWinStreak, 2);
      expect(s.stats!.goalsScored, 7);
      expect(s.personalMatches.first.goalsByPlayer('c'), 0);
    },
  );

  test(
    'snapshot detaches all collection boundaries including scorer history',
    () async {
      final original = _match();
      final f = _Fixture(matches: [original]);
      await f.load();
      final s = f.cubit.state;
      original.scorerIds.clear();
      f.db.players.clear();
      f.db.matches.clear();
      expect(s.personalMatches.single.goalsByPlayer('c'), 1);
      expect(s.players, hasLength(4));
      expect(() => s.players.clear(), throwsUnsupportedError);
      expect(() => s.personalMatches.clear(), throwsUnsupportedError);
      expect(
        () => s.personalMatches.single.scorerIds.clear(),
        throwsUnsupportedError,
      );
      expect(() => s.stats!.badges.clear(), throwsUnsupportedError);
      expect(() => s.profile.recentResults.clear(), throwsUnsupportedError);
      expect(() => s.profile.headToHead.clear(), throwsUnsupportedError);
      expect(
        () => s.profile.mostPlayedOpponent!.playerIds.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => s.profile.mostFrequentTeammate!.playerIds.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'close detaches both repository streams without disposing repositories',
    () async {
      final f = _Fixture();
      await f.load();
      final emitted = <PlayerProfileState>[];
      final subscription = f.cubit.stream.listen(emitted.add);
      await f.cubit.close();
      await f.players.renamePlayer(
        f.players.players.first,
        'Renamed after close',
      );
      await f.repository.deleteMatch('m1');
      await Future<void>.delayed(Duration.zero);
      expect(emitted, isEmpty);
      expect(f.cubit.isClosed, isTrue);
      expect(f.players.players.first.name, 'Renamed after close');
      expect(f.repository.matches, isEmpty);
      await subscription.cancel();
    },
  );
}
