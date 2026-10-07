import 'package:biliardino/cubits/pair_profile/pair_profile_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_database.dart';

void main() {
  test(
    'pair route reacts to corrected/deleted history and archived members; closes safely',
    () async {
      final db = FakeDatabaseHelper(
        players: [
          for (final id in ['a', 'b', 'c', 'd'])
            Player(
              id: id,
              name: id.toUpperCase(),
              isPresent: true,
              createdAt: DateTime(2026),
            ),
        ],
      );
      final players = PlayerRepository(db), matches = MatchRepository(db);
      await players.load();
      await matches.load();
      await matches.addMatch(
        mode: MatchMode.twoVsTwo,
        isRivalry: false,
        team1: ['a', 'b'],
        team2: ['c', 'd'],
        score1: 2,
        score2: 0,
        scorerIds: ['a', 'b'],
      );
      final id = StatsService.computeTeamLeaderboard(
        players.players,
        matches.matches,
      ).first.id;
      final cubit = PairProfileCubit(
        pairId: id,
        playerRepository: players,
        matchRepository: matches,
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.profile!.stats.points, 3);
      await players.archivePlayer(players.players.first);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.profile!.stats.players.first.isArchived, true);
      final original = matches.matches.single;
      await matches.updateMatch(
        original.copyWith(
          t1Score: 0,
          t2Score: 1,
          winningTeam: 2,
          scorerIds: ['c'],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.profile!.stats.points, 0);
      expect(cubit.state.profile!.recentResults, [false]);
      await matches.deleteMatch(original.id);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.profile, isNull);
      await cubit.close();
      await players.renamePlayer(players.players.first, 'Renamed after close');
      await players.dispose();
      await matches.dispose();
    },
  );
}
