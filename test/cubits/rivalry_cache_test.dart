import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/match_rules_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_database.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final mode in MatchMode.values) {
    test(
      '${mode.name}: goals/undo reuse history; save, edit, delete and restore invalidate it',
      () async {
        final db = FakeDatabaseHelper(
          players: [
            for (var i = 1; i <= 4; i++)
              Player(
                id: 'p$i',
                name: 'Player $i',
                createdAt: DateTime(2026),
                isPresent: true,
              ),
          ],
        );
        final players = PlayerRepository(db);
        final matches = MatchRepository(db);
        final rules = MatchRulesRepository(db);
        await Future.wait([players.load(), matches.load(), rules.load()]);
        final cubit = NewMatchCubit(
          playerRepository: players,
          matchRepository: matches,
          matchRulesRepository: rules,
        );
        addTearDown(() async {
          await cubit.close();
          await players.dispose();
          await matches.dispose();
        });
        await flush();
        cubit.setMatchMode(mode);
        cubit.setTeam('p1', 1);
        cubit.setTeam('p3', 2);
        if (mode == MatchMode.twoVsTwo) {
          cubit.setTeam('p2', 1);
          cubit.setTeam('p4', 2);
        }
        cubit.setRivalry(true);
        final emptyHistory = cubit.state.rivalry!;
        expect(emptyHistory.totalMatches, 0);
        cubit.kickoff();
        cubit.addGoal(1, 'p1');
        cubit.addGoal(2, 'p3');
        cubit.removeGoal(2);
        expect(cubit.state.rivalry, same(emptyHistory));
        await matches.load();
        await flush();
        expect(cubit.state.rivalry!.totalMatches, 0);
        await cubit.save();
        await flush();
        expect(cubit.state.rivalry!.team1Wins, 1);
        final savedHistory = cubit.state.rivalry;
        cubit.rematchAfterVictory();
        expect(cubit.state.rivalry, same(savedHistory));
        expect(cubit.state.score1, 0);
        final saved = matches.matches.single;
        await matches.updateMatch(
          saved.copyWith(
            t1Score: 0,
            t2Score: 1,
            winningTeam: 2,
            scorerIds: ['p3'],
          ),
        );
        await flush();
        expect(cubit.state.rivalry!.team2Wins, 1);
        await matches.deleteMatch(saved.id);
        await flush();
        expect(cubit.state.rivalry!.totalMatches, 0);
        db.matches.add(saved);
        await matches.load();
        await flush();
        expect(cubit.state.rivalry!.team1Wins, 1);
        cubit.abortMatch();
        cubit.setTeam('p1', 1);
        expect(cubit.state.rivalry, isNull);
        cubit.setTeam('p3', 2);
        cubit.setTeam('p1', 2);
        cubit.setTeam('p3', 1);
        if (mode == MatchMode.twoVsTwo) {
          cubit.setTeam('p2', 1);
          cubit.setTeam('p4', 2);
          cubit.setTeam('p2', 2);
          cubit.setTeam('p4', 1);
        }
        cubit.setRivalry(true);
        expect(cubit.state.rivalry!.team2Wins, 1);
        final swapped = cubit.state.rivalry;
        await players.renamePlayer(players.players.first, 'New name');
        await flush();
        expect(cubit.state.rivalry, same(swapped));
        await players.togglePresent(players.players.first);
        await flush();
        expect(cubit.state.rivalry, isNull);
      },
    );
  }
}
