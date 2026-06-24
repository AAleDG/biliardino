import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/home/home_cubit.dart';
import '../theme/app_theme.dart';
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
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, int>(
      builder: (context, index) {
        return Scaffold(
          body: IndexedStack(index: index, children: _pages),
          bottomNavigationBar: _BottomNav(
            index: index,
            onSelected: context.read<HomeCubit>().selectTab,
          ),
        );
      },
    );
  }
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
                final tabWidth = constraints.maxWidth / 4;
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
                            boxShadow: [
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
              ],
            ),
          ],
        ),
      );
}
