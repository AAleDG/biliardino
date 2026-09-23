import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_match.dart';
import '../models/player.dart';

/// Presentation owns whole screen compositions, including their widgets/motion.
/// Repositories, application Cubits and navigation state live above this boundary.
abstract interface class AppPresentation {
  String get title;
  ThemeData get theme;
  SystemUiOverlayStyle get systemUi;
  Widget page(AppPage page);
  Widget bootstrap({required bool hasError, required VoidCallback onRetry});
  Widget profile(String playerId);
  Widget matchEditor({
    required GameMatch match,
    required List<Player> players,
    required Future<void> Function(GameMatch) onSave,
  });
}

enum AppPage {
  splash,
  home,
  dashboard,
  players,
  match,
  leaderboard,
  more,
  history,
  data,
}

class AppPresentationScope extends InheritedWidget {
  const AppPresentationScope({
    super.key,
    required this.presentation,
    required super.child,
  });
  final AppPresentation presentation;

  static AppPresentation of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPresentationScope>();
    if (scope == null) {
      throw FlutterError(
        'AppPresentationScope is required above application routes.',
      );
    }
    return scope.presentation;
  }

  @override
  bool updateShouldNotify(AppPresentationScope oldWidget) =>
      !identical(presentation, oldWidget.presentation);
}

/// Kept inside each route so the route can observe presentation changes without
/// replacing the Navigator or moving application state into a style implementation.
class PresentationPage extends StatelessWidget {
  const PresentationPage(this.page, {super.key});
  final AppPage page;
  @override
  Widget build(BuildContext context) =>
      AppPresentationScope.of(context).page(page);
}

class PresentationBuilder extends StatelessWidget {
  const PresentationBuilder({super.key, required this.builder});
  final Widget Function(AppPresentation) builder;
  @override
  Widget build(BuildContext context) =>
      builder(AppPresentationScope.of(context));
}
