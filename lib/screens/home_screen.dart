import '../widgets/selection_motion.dart';
import '../presentation/app_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/home/home_cubit.dart';
import '../cubits/new_match/new_match_cubit.dart';
import '../cubits/new_match/new_match_state.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeDestination>(
      builder: (context, destination) {
        final selectedPage = _homeEntries.indexWhere(
          (entry) => entry.destination == destination,
        );
        final index = selectedPage < 0 ? _homeEntries.length - 1 : selectedPage;
        return BlocSelector<
          NewMatchCubit,
          NewMatchState,
          ({bool isStarted, bool isSaving})
        >(
          selector: (state) =>
              (isStarted: _isStartedMatch(state), isSaving: state.isSaving),
          builder: (context, matchGate) {
            final active = AppPresentationScope.isActiveOf(context);
            return PopScope(
              canPop: !active || !matchGate.isStarted,
              onPopInvokedWithResult: (didPop, result) async {
                if (!active) return;
                if (didPop) {
                  return;
                }
                if (matchGate.isSaving) {
                  return;
                }
                final canLeave = await _confirmLeaveStartedMatch(context);
                if (!context.mounted || !canLeave) {
                  return;
                }
                context.read<NewMatchCubit>().abortMatch();
                Navigator.of(context).pop(result);
              },
              child: Scaffold(
                body: SelectionFade(
                  selection: index,
                  child: IndexedStack(
                    index: index,
                    children: [
                      for (var page = 0; page < _homeEntries.length; page++)
                        TickerMode(
                          enabled: page == index,
                          child: _homeEntries[page].page,
                        ),
                    ],
                  ),
                ),
                bottomNavigationBar: _BottomNav(
                  destination: destination,
                  onSelected: (selected) => _selectDestination(
                    context,
                    current: destination,
                    selected: selected,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

bool _isStartedMatch(NewMatchState state) =>
    state.kickedOff && state.lastVictory == null;

Future<void> _selectDestination(
  BuildContext context, {
  required HomeDestination current,
  required HomeDestination selected,
}) async {
  if (current == selected) {
    return;
  }
  final leavingMatchTab =
      current == HomeDestination.match && selected != HomeDestination.match;
  final matchState = context.read<NewMatchCubit>().state;
  if (leavingMatchTab && matchState.isSaving) {
    return;
  }
  if (leavingMatchTab && _isStartedMatch(matchState)) {
    final canLeave = await _confirmLeaveStartedMatch(context);
    if (!context.mounted || !canLeave) {
      return;
    }
    context.read<NewMatchCubit>().abortMatch();
  }
  if (context.mounted) {
    context.read<HomeCubit>().select(selected);
  }
}

Future<bool> _confirmLeaveStartedMatch(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Uscire dalla partita?'),
      content: const Text('La partita in corso verrà annullata.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Resta'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: AppTheme.primaryButton(
            background: AppColors.error,
            pressed: AppColors.error,
          ),
          child: const Text('Esci'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.destination, required this.onSelected});

  final HomeDestination destination;
  final ValueChanged<HomeDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedPage = _homeEntries.indexWhere(
      (entry) => entry.destination == destination,
    );
    final selectedIndex = selectedPage < 0
        ? _homeEntries.length - 1
        : selectedPage;
    return Material(
      color: AppColors.surface,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationSelectionIndicator(
            index: selectedIndex,
            count: _homeEntries.length,
            color: AppColors.primary,
          ),
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.3),
            ),
            child: NavigationBar(
              animationDuration: Duration.zero,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  onSelected(_homeEntries[index].destination),
              destinations: [
                for (final entry in _homeEntries) entry.navigation,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeEntry {
  const _HomeEntry({
    required this.destination,
    required this.page,
    required this.navigation,
  });

  final HomeDestination destination;
  final Widget page;
  final NavigationDestination navigation;
}

const _homeEntries = [
  _HomeEntry(
    destination: HomeDestination.home,
    page: PresentationPage(AppPage.dashboard),
    navigation: NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
  ),
  _HomeEntry(
    destination: HomeDestination.players,
    page: PresentationPage(AppPage.players),
    navigation: NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Giocatori',
    ),
  ),
  _HomeEntry(
    destination: HomeDestination.match,
    page: PresentationPage(AppPage.match),
    navigation: NavigationDestination(
      icon: Icon(Icons.sports_soccer_outlined),
      selectedIcon: Icon(Icons.sports_soccer),
      label: 'Partita',
    ),
  ),
  _HomeEntry(
    destination: HomeDestination.leaderboard,
    page: PresentationPage(AppPage.leaderboard),
    navigation: NavigationDestination(
      icon: Icon(Icons.leaderboard_outlined),
      selectedIcon: Icon(Icons.leaderboard),
      label: 'Classifica',
    ),
  ),
  _HomeEntry(
    destination: HomeDestination.more,
    page: PresentationPage(AppPage.more),
    navigation: NavigationDestination(
      icon: Icon(Icons.more_horiz),
      label: 'Altro',
    ),
  ),
];
