import 'package:intl/date_symbol_data_local.dart';
import 'presentation/italia90/theme/italia90_motion.dart';
import 'cubits/app_style/app_style_cubit.dart';
import 'repositories/app_style_repository.dart';
import 'repositories/feedback_repository.dart';
import 'repositories/data_management_repository.dart';
import 'services/data_management_coordinator.dart';
import 'services/data_file_share_service.dart';
import 'services/backup_file_picker.dart';
import 'services/csv_share_service.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubits/dashboard/dashboard_cubit.dart';
import 'cubits/history/history_cubit.dart';
import 'cubits/home/home_cubit.dart';
import 'cubits/leaderboard/leaderboard_cubit.dart';
import 'cubits/new_match/new_match_cubit.dart';
import 'cubits/players/players_cubit.dart';
import 'data/database_helper.dart';
import 'repositories/match_repository.dart';
import 'repositories/match_rules_repository.dart';
import 'repositories/player_repository.dart';
import 'models/app_style.dart';
import 'presentation/app_presentation.dart';
import 'presentation/presentation_operations.dart';
import 'presentation/presentation_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    presentationFor(AppStyle.southAfrica2010).systemUi,
  );

  await initializeDateFormatting('it_IT');
  runApp(const BiliardinoBootstrap());
}

class BiliardinoBootstrap extends StatefulWidget {
  const BiliardinoBootstrap({
    super.key,
    this.playerRepository,
    this.matchRepository,
    this.matchRulesRepository,
    this.dataManagementRepository,
    this.appStyleRepository,
  }) : assert(
         (playerRepository == null) == (matchRepository == null) &&
             (playerRepository == null) == (matchRulesRepository == null) &&
             (playerRepository == null) == (dataManagementRepository == null) &&
             (playerRepository == null) == (appStyleRepository == null),
         'Inject all repositories, including data management and style, or none.',
       );

  final PlayerRepository? playerRepository;
  final MatchRepository? matchRepository;
  final MatchRulesRepository? matchRulesRepository;
  final DataManagementRepository? dataManagementRepository;
  final AppStyleRepository? appStyleRepository;

  @override
  State<BiliardinoBootstrap> createState() => _BiliardinoBootstrapState();
}

class _BiliardinoBootstrapState extends State<BiliardinoBootstrap> {
  late final PlayerRepository _playerRepository;
  late final MatchRepository _matchRepository;
  late final MatchRulesRepository _matchRulesRepository;
  late final DataManagementRepository _dataManagementRepository;
  late final AppStyleRepository _appStyleRepository;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _playerRepository =
        widget.playerRepository ?? PlayerRepository(DatabaseHelper.instance);
    _matchRepository =
        widget.matchRepository ?? MatchRepository(DatabaseHelper.instance);
    _matchRulesRepository =
        widget.matchRulesRepository ??
        MatchRulesRepository(DatabaseHelper.instance);
    _dataManagementRepository =
        widget.dataManagementRepository ??
        DataManagementCoordinator(
          database: DatabaseHelper.instance,
          refresh: () async {
            await Future.wait([
              _playerRepository.load(),
              _matchRepository.load(),
            ]);
          },
        );
    _appStyleRepository =
        widget.appStyleRepository ??
        AppStyleRepository(DatabaseHelper.instance);
    _loadFuture = _loadRepositories();
  }

  Future<void> _loadRepositories() async {
    await Future.wait([
      _playerRepository.load(),
      _matchRepository.load(),
      _matchRulesRepository.load(),
      _appStyleRepository.load(),
    ]);
  }

  void _retry() {
    setState(() {
      _loadFuture = _loadRepositories();
    });
  }

  @override
  void dispose() {
    unawaited(_playerRepository.dispose());
    unawaited(_matchRepository.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return BiliardinoApp(
            playerRepository: _playerRepository,
            matchRepository: _matchRepository,
            matchRulesRepository: _matchRulesRepository,
            dataManagementRepository: _dataManagementRepository,
            appStyleRepository: _appStyleRepository,
          );
        }

        return _BiliardinoMaterialApp(
          home: PresentationBuilder(
            builder: (presentation) => presentation.bootstrap(
              hasError: snapshot.hasError,
              onRetry: _retry,
            ),
          ),
        );
      },
    );
  }
}

class BiliardinoApp extends StatelessWidget {
  const BiliardinoApp({
    super.key,
    required this.playerRepository,
    required this.matchRepository,
    required this.matchRulesRepository,
    required this.dataManagementRepository,
    required this.appStyleRepository,
    this.feedbackRepository,
  });

  final PlayerRepository playerRepository;
  final MatchRepository matchRepository;
  final MatchRulesRepository matchRulesRepository;
  final DataManagementRepository dataManagementRepository;
  final AppStyleRepository appStyleRepository;
  final FeedbackRepository? feedbackRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FeedbackRepository>(
          create: (_) =>
              feedbackRepository ?? FeedbackRepository(DatabaseHelper.instance),
        ),
        RepositoryProvider<AppStyleRepository>.value(value: appStyleRepository),
        RepositoryProvider<DataManagementRepository>.value(
          value: dataManagementRepository,
        ),
        RepositoryProvider<BackupFilePicker>(
          create: (_) => const BackupFilePicker(),
        ),
        RepositoryProvider<DataFileShareService>(
          create: (_) => DataFileShareService.platform(),
        ),
        RepositoryProvider<CsvShareService>(
          create: (_) => CsvShareService.platform(),
        ),
        RepositoryProvider<PlayerRepository>.value(value: playerRepository),
        RepositoryProvider<MatchRepository>.value(value: matchRepository),
        RepositoryProvider<MatchRulesRepository>.value(
          value: matchRulesRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppStyleCubit>(
            create: (_) => AppStyleCubit(appStyleRepository),
          ),
          BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
          BlocProvider<DashboardCubit>(
            create: (ctx) => DashboardCubit(
              playerRepository: ctx.read<PlayerRepository>(),
              matchRepository: ctx.read<MatchRepository>(),
            ),
          ),
          BlocProvider<HistoryCubit>(
            create: (ctx) => HistoryCubit(
              playerRepository: ctx.read<PlayerRepository>(),
              matchRepository: ctx.read<MatchRepository>(),
            ),
          ),
          BlocProvider<PlayersCubit>(
            create: (ctx) => PlayersCubit(ctx.read<PlayerRepository>()),
          ),
          BlocProvider<LeaderboardCubit>(
            create: (ctx) => LeaderboardCubit(
              playerRepository: ctx.read<PlayerRepository>(),
              matchRepository: ctx.read<MatchRepository>(),
            ),
          ),
          BlocProvider<NewMatchCubit>(
            create: (ctx) => NewMatchCubit(
              playerRepository: ctx.read<PlayerRepository>(),
              matchRepository: ctx.read<MatchRepository>(),
              matchRulesRepository: ctx.read<MatchRulesRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<AppStyleCubit, AppStyle>(
          builder: (context, style) => _BiliardinoMaterialApp(
            style: style,
            home: const PresentationPage(AppPage.splash),
          ),
        ),
      ),
    );
  }
}

class _BiliardinoMaterialApp extends StatelessWidget {
  const _BiliardinoMaterialApp({
    required this.home,
    this.style = AppStyle.southAfrica2010,
  });

  final Widget home;
  final AppStyle style;

  @override
  Widget build(BuildContext context) {
    final presentation = presentationFor(style);
    return AppPresentationScope(
      presentation: presentation,
      child: PresentationOperationHost(
        child: Italia90MotionScope(
          child: MaterialApp(
            title: presentation.title,
            debugShowCheckedModeBanner: false,
            theme: presentation.theme,
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: presentation.systemUi,
              child: child!,
            ),
            home: home,
          ),
        ),
      ),
    );
  }
}
