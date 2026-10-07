import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/home/home_cubit.dart';
import '../../models/app_style.dart';
import '../../models/game_match.dart';
import '../../models/player.dart';
import '../app_presentation.dart';
import 'bootstrap_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/data_management_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/match_editor/match_editor_screen.dart';
import 'screens/more_screen.dart';
import 'screens/new_match_screen.dart';
import 'screens/pair_profile_screen.dart';
import 'screens/player_profile_screen.dart';
import 'screens/players_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/italia90_tokens.dart';

class Italia90Presentation implements AppPresentation {
  const Italia90Presentation();
  @override
  AppStyle get style => AppStyle.italia90;
  @override
  String get title => 'NTT Biliardino';
  @override
  ThemeData get theme => AppTheme.italia90();
  @override
  SystemUiOverlayStyle get systemUi => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Italia90.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  @override
  Widget page(AppPage page) => switch (page) {
    AppPage.splash => const SplashScreen(),
    AppPage.home => const HomeScreen(),
    AppPage.dashboard => const DashboardScreen(),
    AppPage.players => const PlayersScreen(),
    AppPage.match => const NewMatchScreen(),
    AppPage.leaderboard => const LeaderboardScreen(),
    AppPage.more => const MoreScreen(),
    AppPage.history => const HistoryScreen(),
    AppPage.data => const DataManagementScreen(),
  };
  @override
  Widget bootstrap({required bool hasError, required VoidCallback onRetry}) =>
      Italia90BootstrapScreen(hasError: hasError, onRetry: onRetry);
  @override
  Widget profile(String playerId) => PlayerProfileScreen(playerId: playerId);
  @override
  Widget pairProfile(String pairId) => PairProfileScreen(pairId: pairId);
  @override
  Widget matchEditor({
    required GameMatch match,
    required List<Player> players,
    required Future<void> Function(GameMatch) onSave,
  }) => MatchEditorScreen(match: match, players: players, onSave: onSave);
  Future<void> _open(
    BuildContext context,
    HomeDestination destination,
    AppPage page,
  ) async {
    try {
      context.read<HomeCubit>().select(destination);
    } on ProviderNotFoundException {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => PresentationPage(page)),
      );
    }
  }

  @override
  Future<void> openHistory(BuildContext context) =>
      _open(context, HomeDestination.history, AppPage.history);
  @override
  Future<void> openData(BuildContext context) =>
      _open(context, HomeDestination.data, AppPage.data);
}
