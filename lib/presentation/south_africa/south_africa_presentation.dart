import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../models/app_style.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/data_management_screen.dart';
import '../../screens/history_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/leaderboard_screen.dart';
import '../../screens/match_editor/match_editor_screen.dart';
import '../../screens/more_screen.dart';
import '../../screens/new_match_screen.dart';
import '../../screens/player_profile_screen.dart';
import '../../screens/pair_profile_screen.dart';
import '../../screens/players_screen.dart';
import '../../screens/splash_screen.dart';
import '../../theme/app_theme.dart';
import '../app_presentation.dart';
import 'bootstrap_screen.dart';

/// Reuses the existing South Africa compositions without changing their visuals.
class SouthAfricaPresentation implements AppPresentation {
  const SouthAfricaPresentation();
  @override
  AppStyle get style => AppStyle.southAfrica2010;
  @override
  String get title => 'NTT Biliardino';
  @override
  ThemeData get theme => AppTheme.southAfrica();
  @override
  SystemUiOverlayStyle get systemUi => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
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
      SouthAfricaBootstrapScreen(hasError: hasError, onRetry: onRetry);
  @override
  Widget profile(String playerId) => PlayerProfileScreen(playerId: playerId);
  @override
  Widget pairProfile(String pairId) => PairProfileScreen(pairId: pairId);
  @override
  Future<void> openHistory(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PresentationPage(AppPage.history),
    ),
  );
  @override
  Future<void> openData(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PresentationPage(AppPage.data),
    ),
  );
  @override
  Widget matchEditor({
    required GameMatch match,
    required List<Player> players,
    required Future<void> Function(GameMatch) onSave,
  }) => MatchEditorScreen(match: match, players: players, onSave: onSave);
}
