import 'package:biliardino/presentation/app_presentation.dart';
import 'package:biliardino/presentation/south_africa/south_africa_presentation.dart';
import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/screens/leaderboard_screen.dart';
import 'package:biliardino/services/csv_share_service.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'fake_database.dart';

/// Synthetic repository data, never installed in persistent application storage.
class LeaderboardFixture {
  LeaderboardFixture({
    int count = 4,
    bool longNames = false,
    bool legacy = false,
  }) {
    // A one-entrant view models a historical opponent no longer in the roster.
    final players = [
      for (var i = 0; i < count; i++)
        Player(
          id: 'p$i',
          name: longNames
              ? 'Giocatore $i Alessandro Antonio Delgaudio'
              : 'Player $i',
          createdAt: DateTime(2026),
          isPresent: true,
        ),
    ];
    final matches = [
      for (var i = 0; i < count; i += 2)
        GameMatch(
          id: 'm$i',
          playedAt: DateTime(2026, 1, i + 1),
          mode: MatchMode.oneVsOne,
          isRivalry: false,
          t1p1: 'p$i',
          t1p2: '',
          t2p1: 'p${i + 1}',
          t2p2: '',
          t1Score: 2,
          t2Score: 1,
          winningTeam: 1,
          scorerIds: legacy ? const [] : ['p$i', 'p$i', 'p${i + 1}'],
        ),
    ];
    database = FakeDatabaseHelper(players: players, matches: matches);
    playersRepository = PlayerRepository(database);
    matchesRepository = MatchRepository(database);
  }
  late final FakeDatabaseHelper database;
  late final PlayerRepository playersRepository;
  late final MatchRepository matchesRepository;
  late final LeaderboardCubit cubit;
  Future<void> load() async {
    await playersRepository.load();
    await matchesRepository.load();
    cubit = LeaderboardCubit(
      playerRepository: playersRepository,
      matchRepository: matchesRepository,
    );
  }

  Widget app({CsvShareService? share}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: playersRepository),
      RepositoryProvider.value(value: matchesRepository),
      RepositoryProvider.value(value: share ?? CsvShareService.platform()),
    ],
    child: BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        builder: (context, child) => AppPresentationScope(
          presentation: const SouthAfricaPresentation(),
          child: child!,
        ),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.southAfrica(),
        home: const LeaderboardScreen(),
      ),
    ),
  );
  Future<void> dispose() async {
    await cubit.close();
    await playersRepository.dispose();
    await matchesRepository.dispose();
  }
}
