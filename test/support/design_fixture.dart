import 'package:biliardino/presentation/app_presentation.dart';
import 'package:biliardino/presentation/south_africa/south_africa_presentation.dart';
import 'package:biliardino/repositories/app_style_repository.dart';
import 'package:biliardino/repositories/feedback_repository.dart';
import 'package:biliardino/repositories/data_management_repository.dart';
import 'package:biliardino/services/data_management_coordinator.dart';
import 'package:biliardino/services/data_file_share_service.dart';
import 'package:biliardino/services/backup_file_picker.dart';
import 'package:biliardino/services/csv_share_service.dart';
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
import 'package:biliardino/cubits/dashboard/dashboard_cubit.dart';
import 'package:biliardino/cubits/history/history_cubit.dart';
import 'package:biliardino/cubits/players/players_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/theme/app_theme.dart';

import 'fake_database.dart';

/// Deterministic visual fixtures through the real repositories and app widgets.
/// These in-memory captures do not establish native storage/share correctness.
class DesignFixture {
  DesignFixture({
    bool empty = false,
    this.csvShareService,
    PlayerRepository Function(FakeDatabaseHelper)? playerRepositoryFactory,
    bool longRoster = false,
    bool populatedDashboard = false,
    bool sparseDashboard = false,
  }) {
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
          : populatedDashboard
          ? _dashboardMatches(longRoster: longRoster)
          : sparseDashboard
          ? [_dashboardMatches(longRoster: longRoster).first]
          : [
              GameMatch(
                id: 'm1',
                playedAt: DateTime(2026, 1, 7, 13, 30),
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
    playersRepository =
        playerRepositoryFactory?.call(database) ?? PlayerRepository(database);
    matchesRepository = MatchRepository(database);
    rulesRepository = MatchRulesRepository(database);
    styleRepository = AppStyleRepository(database);
  }
  final CsvShareService? csvShareService;
  FeedbackRepository? feedbackRepository;
  late final FakeDatabaseHelper database;
  late final PlayerRepository playersRepository;
  late final MatchRepository matchesRepository;
  late final MatchRulesRepository rulesRepository;
  late final AppStyleRepository styleRepository;
  Future<void> load() async => Future.wait([
    playersRepository.load(),
    matchesRepository.load(),
    rulesRepository.load(),
    styleRepository.load(),
  ]);
  Widget get app => BiliardinoApp(
    playerRepository: playersRepository,
    matchRepository: matchesRepository,
    matchRulesRepository: rulesRepository,
    dataManagementRepository: dataCoordinator,
    appStyleRepository: styleRepository,
    feedbackRepository: feedbackRepository,
  );

  DataManagementRepository get dataCoordinator => DataManagementCoordinator(
    database: database,
    refresh: () async {
      await Future.wait([playersRepository.load(), matchesRepository.load()]);
    },
  );

  /// Isolates screen checks from the separately tested bootstrap/splash route.
  Widget get home => homeWithPresentation(const SouthAfricaPresentation());

  Widget homeWithPresentation(AppPresentation presentation) =>
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<DataManagementRepository>(
            create: (_) => dataCoordinator,
          ),
          RepositoryProvider<BackupFilePicker>(
            create: (_) => const BackupFilePicker(),
          ),
          RepositoryProvider<DataFileShareService>(
            create: (_) => DataFileShareService.platform(),
          ),
          RepositoryProvider<CsvShareService>(
            create: (_) => csvShareService ?? CsvShareService.platform(),
          ),
          RepositoryProvider<PlayerRepository>.value(value: playersRepository),
          RepositoryProvider<MatchRepository>.value(value: matchesRepository),
          RepositoryProvider<MatchRulesRepository>.value(
            value: rulesRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => HomeCubit()),
            BlocProvider(
              create: (_) => DashboardCubit(
                playerRepository: playersRepository,
                matchRepository: matchesRepository,
              ),
            ),
            BlocProvider(
              create: (_) => HistoryCubit(
                playerRepository: playersRepository,
                matchRepository: matchesRepository,
              ),
            ),
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
            builder: (context, child) =>
                AppPresentationScope(presentation: presentation, child: child!),
            debugShowCheckedModeBanner: false,
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

List<GameMatch> _dashboardMatches({required bool longRoster}) {
  GameMatch match({
    required String id,
    required DateTime playedAt,
    required String teamOne,
    required String teamTwo,
    required int scoreOne,
    required int scoreTwo,
  }) {
    return GameMatch(
      id: id,
      playedAt: playedAt,
      mode: MatchMode.oneVsOne,
      isRivalry: false,
      t1p1: teamOne,
      t1p2: '',
      t2p1: teamTwo,
      t2p2: '',
      t1Score: scoreOne,
      t2Score: scoreTwo,
      winningTeam: scoreOne > scoreTwo ? 1 : 2,
      scorerIds: [
        ...List.filled(scoreOne, teamOne),
        ...List.filled(scoreTwo, teamTwo),
      ],
    );
  }

  return [
    match(
      id: 'dashboard-5',
      playedAt: DateTime(2026, 9, 8, 18, 30),
      teamOne: 'p0',
      teamTwo: 'p1',
      scoreOne: 5,
      scoreTwo: 3,
    ),
    match(
      id: 'dashboard-4',
      playedAt: DateTime(2026, 9, 8, 17, 15),
      teamOne: 'p2',
      teamTwo: 'p3',
      scoreOne: 2,
      scoreTwo: 5,
    ),
    match(
      id: 'dashboard-3',
      playedAt: DateTime(2026, 9, 7, 16, 20),
      teamOne: 'p4',
      teamTwo: 'p5',
      scoreOne: 5,
      scoreTwo: 4,
    ),
    match(
      id: 'dashboard-2',
      playedAt: DateTime(2026, 9, 6, 14, 45),
      teamOne: 'p1',
      teamTwo: 'p2',
      scoreOne: 5,
      scoreTwo: 1,
    ),
    match(
      id: 'dashboard-1',
      playedAt: DateTime(2026, 9, 5, 12, 10),
      teamOne: longRoster ? 'p6' : 'p3',
      teamTwo: longRoster ? 'p7' : 'p4',
      scoreOne: 3,
      scoreTwo: 5,
    ),
  ];
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
