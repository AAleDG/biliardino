import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF142340),
      systemNavigationBarIconBrightness: Brightness.light,
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
  }) : assert(
         (playerRepository == null) == (matchRepository == null) &&
             (playerRepository == null) == (matchRulesRepository == null),
         'Inject all repositories or none.',
       );

  final PlayerRepository? playerRepository;
  final MatchRepository? matchRepository;
  final MatchRulesRepository? matchRulesRepository;

  @override
  State<BiliardinoBootstrap> createState() => _BiliardinoBootstrapState();
}

class _BiliardinoBootstrapState extends State<BiliardinoBootstrap> {
  late final PlayerRepository _playerRepository;
  late final MatchRepository _matchRepository;
  late final MatchRulesRepository _matchRulesRepository;
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
    _loadFuture = _loadRepositories();
  }

  Future<void> _loadRepositories() async {
    await Future.wait([
      _playerRepository.load(),
      _matchRepository.load(),
      _matchRulesRepository.load(),
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
  });

  final PlayerRepository playerRepository;
  final MatchRepository matchRepository;
  final MatchRulesRepository matchRulesRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PlayerRepository>.value(value: playerRepository),
        RepositoryProvider<MatchRepository>.value(value: matchRepository),
        RepositoryProvider<MatchRulesRepository>.value(
          value: matchRulesRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
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
      theme: AppTheme.dark(),
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
