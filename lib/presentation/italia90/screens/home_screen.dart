import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app_presentation.dart';

import '../../../cubits/home/home_cubit.dart';
import '../../../cubits/new_match/new_match_cubit.dart';
import '../../../cubits/new_match/new_match_state.dart';
import '../theme/italia90_motion.dart';
import '../theme/italia90_tokens.dart';
import 'dashboard_screen.dart';
import 'leaderboard_screen.dart';
import 'data_management_screen.dart';
import 'history_screen.dart';
import 'more_screen.dart';
import 'new_match_screen.dart';
import 'players_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeDestination>(
      builder: (context, destination) {
        final index = _pageEntries.indexWhere(
          (entry) => entry.destination == destination,
        );
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
                if (didPop || matchGate.isSaving) {
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
                body: IndexedStack(
                  index: index,
                  children: [
                    for (var page = 0; page < _pageEntries.length; page++)
                      TickerMode(
                        enabled: page == index,
                        child: _pageEntries[page].page,
                      ),
                  ],
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
      content: const Text('La partita in corso verra annullata.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Resta'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
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
    final selectedIndex = _visibleEntries.indexWhere(
      (entry) => entry.destination == destination,
    );
    final visibleIndex = selectedIndex < 0
        ? _visibleEntries.length - 1
        : selectedIndex;
    return Material(
      color: Italia90.surface,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _visibleEntries.length;
              return SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: Italia90Motion.durationOf(
                        context,
                        Italia90Motion.navigation,
                      ),
                      curve: Curves.easeOutCubic,
                      left: tabWidth * visibleIndex + tabWidth * .30,
                      width: tabWidth * .40,
                      height: 3,
                      child: const ColoredBox(color: Italia90.primary),
                    ),
                  ],
                ),
              );
            },
          ),
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.3),
            ),
            child: NavigationBar(
              selectedIndex: visibleIndex,
              onDestinationSelected: (index) =>
                  onSelected(_visibleEntries[index].destination),
              destinations: [
                for (final entry in _visibleEntries) entry.navigation!,
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
  final NavigationDestination? navigation;
}

const _visibleEntries = [
  _HomeEntry(
    destination: HomeDestination.home,
    page: DashboardScreen(),
    navigation: NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
  ),
  _HomeEntry(
    destination: HomeDestination.players,
    page: PlayersScreen(),
    navigation: NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Giocatori',
    ),
  ),
  _HomeEntry(
    destination: HomeDestination.match,
    page: NewMatchScreen(),
    navigation: NavigationDestination(
      icon: Icon(Icons.sports_soccer_outlined),
      selectedIcon: Icon(Icons.sports_soccer),
      label: 'Partita',
    ),
  ),
  _HomeEntry(
    destination: HomeDestination.leaderboard,
    page: LeaderboardScreen(),
    navigation: NavigationDestination(
      icon: Icon(Icons.leaderboard_outlined),
      selectedIcon: Icon(Icons.leaderboard),
      label: 'Classifica',
    ),
  ),
  _HomeEntry(
    destination: HomeDestination.more,
    page: MoreScreen(),
    navigation: NavigationDestination(
      icon: Icon(Icons.more_horiz),
      selectedIcon: Icon(Icons.more_horiz),
      label: 'Altro',
    ),
  ),
];

const _pageEntries = [
  ..._visibleEntries,
  _HomeEntry(
    destination: HomeDestination.history,
    page: HistoryScreen(showBack: false),
    navigation: null,
  ),
  _HomeEntry(
    destination: HomeDestination.data,
    page: DataManagementScreen(showBack: false),
    navigation: null,
  ),
];
