import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/cubits/leaderboard/leaderboard_state.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/models/player_badge.dart';
import 'package:biliardino/models/player_stats.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_database.dart';

void main() {
  Player player(String id, String name) =>
      Player(id: id, name: name, isPresent: true, createdAt: DateTime(2026));
  test(
    'scorers use goals then games then case-insensitive name; exclude zero goals',
    () {
      PlayerStats stats(String name, int games, int goals) => PlayerStats(
        player: player(name, name),
        games: games,
        wins: 0,
        losses: games,
        goalsScored: goals,
      );
      final state = LeaderboardState(
        stats: [
          stats('zeta', 1, 5),
          stats('Bea', 2, 3),
          stats('anna', 2, 3),
          stats('Carlo', 1, 3),
          stats('No goals', 4, 0),
          stats('No games', 0, 0),
        ],
      );
      expect(state.scorers.map((s) => s.player.name), [
        'zeta',
        'anna',
        'Bea',
        'Carlo',
      ]);
      expect(state.general, hasLength(5));
      expect(() => state.scorers.clear(), throwsUnsupportedError);
    },
  );
  test('state and nested badges snapshot caller-owned lists', () {
    final badges = <PlayerBadge>[
      const PlayerBadge(code: 'leader', label: 'Leader', description: 'Test'),
    ];
    final stats = <PlayerStats>[
      PlayerStats(
        player: player('a', 'Anna'),
        games: 1,
        wins: 1,
        losses: 0,
        goalsScored: 1,
        badges: badges,
      ),
    ];
    final state = LeaderboardState(stats: stats);
    badges.clear();
    stats.clear();
    expect(state.stats.single.badges, hasLength(1));
    expect(() => state.stats.clear(), throwsUnsupportedError);
    expect(() => state.stats.single.badges.clear(), throwsUnsupportedError);
    expect(state.copyWith().stats.single.player.id, 'a');
  });
  test(
    'rename emits even if ranking order and all metrics stay equal',
    () async {
      final db = FakeDatabaseHelper(players: [player('a', 'Marco')]);
      final players = PlayerRepository(db), matches = MatchRepository(db);
      await players.load();
      await matches.load();
      final cubit = LeaderboardCubit(
        playerRepository: players,
        matchRepository: matches,
      );
      addTearDown(() async {
        await cubit.close();
        await players.dispose();
        await matches.dispose();
      });
      await Future<void>.delayed(Duration.zero);
      final updated = cubit.stream.first;
      await players.renamePlayer(players.players.single, 'Mario');
      expect((await updated).stats.single.player.name, 'Mario');
    },
  );
  test(
    'match add/edit/delete react; archived players retain historical stats; close cancels',
    () async {
      final db = FakeDatabaseHelper(
        players: [player('a', 'Anna'), player('b', 'Bea')],
      );
      final players = PlayerRepository(db), matches = MatchRepository(db);
      await players.load();
      await matches.load();
      final cubit = LeaderboardCubit(
        playerRepository: players,
        matchRepository: matches,
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.general, isEmpty);
      await matches.addMatch(
        mode: MatchMode.oneVsOne,
        isRivalry: false,
        team1: ['a'],
        team2: ['b'],
        score1: 2,
        score2: 0,
        scorerIds: ['a', 'a'],
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.general.first.player.id, 'a');
      expect(cubit.state.general.first.points, 3);
      expect(cubit.state.scorers.single.goalsScored, 2);
      final old = matches.matches.single;
      await matches.updateMatch(
        GameMatch(
          id: old.id,
          playedAt: old.playedAt,
          mode: old.mode,
          isRivalry: false,
          t1p1: 'a',
          t1p2: '',
          t2p1: 'b',
          t2p2: '',
          t1Score: 0,
          t2Score: 1,
          winningTeam: 2,
          scorerIds: ['b'],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.general.first.player.id, 'b');
      expect(cubit.state.scorers.single.player.id, 'b');
      await players.archivePlayer(
        players.players.firstWhere((p) => p.id == 'b'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.general.first.player.id, 'b');
      await matches.deleteMatch(old.id);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.general, isEmpty);
      await cubit.close();
      await players.renamePlayer(players.players.first, 'Renamed');
      await players.dispose();
      await matches.dispose();
    },
  );
}
