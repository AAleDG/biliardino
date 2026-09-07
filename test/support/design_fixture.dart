import 'package:biliardino/main.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/match_rules_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/players/players_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/theme/app_theme.dart';

import 'fake_database.dart';

/// Deterministic visual fixtures through the real repositories and app widgets.
/// These in-memory captures do not establish native storage/share correctness.
class DesignFixture {
  DesignFixture({bool empty = false, bool longRoster = false}) {
    final names = [
      'Andrea',
      'Giulia',
      'Luca',
      'Marco',
      'Paolo',
      'Sara',
      if (longRoster) ...[
        'Alessandro Antonio Delgaudio',
        'Beatrice Lunghissimo Cognome',
      ],
    ];
    final players = empty
        ? <Player>[]
        : [
            for (var i = 0; i < names.length; i++)
              Player(
                id: 'p$i',
                name: names[i],
                createdAt: DateTime(2026, 9, 1),
                isPresent: longRoster || ![1, 5].contains(i),
              ),
          ];
    database = FakeDatabaseHelper(
      players: players,
      matches: empty
          ? []
          : [
              GameMatch(
                id: 'm1',
                playedAt: DateTime(2026, 9, 7, 13, 30),
                mode: MatchMode.twoVsTwo,
                isRivalry: false,
                t1p1: 'p0',
                t1p2: 'p2',
                t2p1: 'p3',
                t2p2: 'p4',
                t1Score: 4,
                t2Score: 5,
                winningTeam: 2,
                scorerIds: const [
                  'p0',
                  'p3',
                  'p2',
                  'p4',
                  'p0',
                  'p3',
                  'p2',
                  'p4',
                  'p3',
                ],
              ),
            ],
    );
    playersRepository = PlayerRepository(database);
    matchesRepository = MatchRepository(database);
    rulesRepository = MatchRulesRepository(database);
  }
  late final FakeDatabaseHelper database;
  late final PlayerRepository playersRepository;
  late final MatchRepository matchesRepository;
  late final MatchRulesRepository rulesRepository;
  Future<void> load() async => Future.wait([
    playersRepository.load(),
    matchesRepository.load(),
    rulesRepository.load(),
  ]);
  Widget get app => BiliardinoApp(
    playerRepository: playersRepository,
    matchRepository: matchesRepository,
    matchRulesRepository: rulesRepository,
  );

  /// Isolates screen checks from the separately tested bootstrap/splash route.
  Widget get home => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<PlayerRepository>.value(value: playersRepository),
      RepositoryProvider<MatchRepository>.value(value: matchesRepository),
      RepositoryProvider<MatchRulesRepository>.value(value: rulesRepository),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeCubit()),
        BlocProvider(create: (_) => PlayersCubit(playersRepository)),
        BlocProvider(
          create: (_) => NewMatchCubit(
            playerRepository: playersRepository,
            matchRepository: matchesRepository,
            matchRulesRepository: rulesRepository,
          ),
        ),
        BlocProvider(
          create: (_) => LeaderboardCubit(
            playerRepository: playersRepository,
            matchRepository: matchesRepository,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.southAfrica(),
        home: const HomeScreen(),
      ),
    ),
  );
  Future<void> dispose() async {
    await playersRepository.dispose();
    await matchesRepository.dispose();
  }
}

Future<void> loadDesignFonts() async {
  for (final (family, files) in [
    (
      'Barlow',
      ['assets/fonts/Barlow-Regular.ttf', 'assets/fonts/Barlow-SemiBold.ttf'],
    ),
    (
      'Barlow Condensed',
      [
        'assets/fonts/BarlowCondensed-ExtraBold.ttf',
        'assets/fonts/BarlowCondensed-Black.ttf',
      ],
    ),
    ('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load(file));
    }
    await loader.load();
  }
}
