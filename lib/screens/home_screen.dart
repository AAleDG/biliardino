import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/home/home_cubit.dart';
import '../cubits/new_match/new_match_cubit.dart';
import '../cubits/new_match/new_match_state.dart';
import '../theme/app_theme.dart';
import 'data_management_screen.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'new_match_screen.dart';
import 'players_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _pages = [
    PlayersScreen(),
    NewMatchScreen(),
    HistoryScreen(),
    LeaderboardScreen(),
    DataManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, int>(
      builder: (context, index) {
        return BlocBuilder<NewMatchCubit, NewMatchState>(
          builder: (context, matchState) {
            return PopScope(
              canPop: !_isStartedMatch(matchState),
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) {
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
                body: IndexedStack(index: index, children: _pages),
                bottomNavigationBar: _BottomNav(
                  index: index,
                  onSelected: (selectedIndex) => _selectTab(
                    context,
                    currentIndex: index,
                    selectedIndex: selectedIndex,
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

bool _hasStartedMatch(BuildContext context) {
  return _isStartedMatch(context.read<NewMatchCubit>().state);
}

bool _isStartedMatch(NewMatchState state) =>
    state.kickedOff && state.lastVictory == null;

Future<void> _selectTab(
  BuildContext context, {
  required int currentIndex,
  required int selectedIndex,
}) async {
  if (currentIndex == selectedIndex) {
    return;
  }
  final leavingMatchTab = currentIndex == 1 && selectedIndex != 1;
  if (leavingMatchTab && _hasStartedMatch(context)) {
    final canLeave = await _confirmLeaveStartedMatch(context);
    if (!context.mounted || !canLeave) {
      return;
    }
    context.read<NewMatchCubit>().abortMatch();
  }
  if (context.mounted) {
    context.read<HomeCubit>().selectTab(selectedIndex);
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
  const _BottomNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Material(
        color: NttColors.surfaceMid,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 5;
                return SizedBox(
                  height: 3,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                        left: tabWidth * index + tabWidth * 0.30,
                        width: tabWidth * 0.40,
                        height: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: NttColors.accent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: const [
                              BoxShadow(
                                color: NttColors.accent,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            NavigationBar(
              selectedIndex: index,
              onDestinationSelected: onSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Giocatori',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_soccer_outlined),
                  selectedIcon: Icon(Icons.sports_soccer),
                  label: 'Partita',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'Storico',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  selectedIcon: Icon(Icons.leaderboard),
                  label: 'Classifica',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storage_outlined),
                  selectedIcon: Icon(Icons.storage),
                  label: 'Dati',
                ),
              ],
            ),
          ],
        ),
      );
}
