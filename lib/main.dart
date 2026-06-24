import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubits/home/home_cubit.dart';
import 'cubits/leaderboard/leaderboard_cubit.dart';
import 'cubits/players/players_cubit.dart';
import 'data/database_helper.dart';
import 'repositories/match_repository.dart';
import 'repositories/player_repository.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF142340),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final playerRepository = PlayerRepository(DatabaseHelper.instance);
  final matchRepository = MatchRepository(DatabaseHelper.instance);
  await Future.wait([playerRepository.load(), matchRepository.load()]);

  runApp(BiliardinoApp(
    playerRepository: playerRepository,
    matchRepository: matchRepository,
  ));
}

class BiliardinoApp extends StatelessWidget {
  const BiliardinoApp({
    super.key,
    required this.playerRepository,
    required this.matchRepository,
  });

  final PlayerRepository playerRepository;
  final MatchRepository matchRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PlayerRepository>.value(value: playerRepository),
        RepositoryProvider<MatchRepository>.value(value: matchRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
          BlocProvider<PlayersCubit>(
            create: (ctx) =>
                PlayersCubit(ctx.read<PlayerRepository>()),
          ),
          BlocProvider<LeaderboardCubit>(
            create: (ctx) => LeaderboardCubit(
              playerRepository: ctx.read<PlayerRepository>(),
              matchRepository: ctx.read<MatchRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'NTT Biliardino',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
