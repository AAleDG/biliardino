import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'new_match_screen.dart';
import 'players_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _pages = [
    PlayersScreen(),
    NewMatchScreen(),
    HistoryScreen(),
    LeaderboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
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
}
