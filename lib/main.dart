import 'cubits/app_style/app_style_cubit.dart';
import 'repositories/app_style_repository.dart';
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
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
          home: _BootstrapScreen(hasError: snapshot.hasError, onRetry: _retry),
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
  });

  final PlayerRepository playerRepository;
  final MatchRepository matchRepository;
  final MatchRulesRepository matchRulesRepository;
  final DataManagementRepository dataManagementRepository;
  final AppStyleRepository appStyleRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
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
        child: const _BiliardinoMaterialApp(home: SplashScreen()),
      ),
    );
  }
}

class _BiliardinoMaterialApp extends StatelessWidget {
  const _BiliardinoMaterialApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NTT Biliardino',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.southAfrica(),
      home: home,
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen({required this.hasError, required this.onRetry});

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_rounded, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Impossibile caricare i dati.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Controlla il dispositivo e riprova.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      key: const ValueKey('bootstrap-retry'),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('RIPROVA'),
                    ),
                  ],
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Caricamento dati...'),
                  ],
                ),
        ),
      ),
    );
  }
}
