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
        final index = _homeEntries.indexWhere(
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
            return PopScope(
              canPop: !matchGate.isStarted,
              onPopInvokedWithResult: (didPop, result) async {
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
                body: IndexedStack(
                  index: index,
                  children: [
                    for (var page = 0; page < _homeEntries.length; page++)
                      TickerMode(
                        enabled: page == index,
                        child: _homeEntries[page].page,
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
    final selectedIndex = _homeEntries.indexWhere(
      (entry) => entry.destination == destination,
    );
    return Material(
      color: AppColors.surface,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _homeEntries.length;
              return SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: shouldReduceMotion(context)
                          ? Duration.zero
                          : AppMotion.navigation,
                      curve: Curves.easeOutCubic,
                      left: tabWidth * selectedIndex + tabWidth * 0.30,
                      width: tabWidth * 0.40,
                      height: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
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
