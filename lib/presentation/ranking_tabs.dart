import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/leaderboard/leaderboard_cubit.dart';
import '../cubits/leaderboard/leaderboard_state.dart';

/// Synchronizes the original per-view tab controllers through the shared owner.
class RankingTabs extends StatelessWidget {
  const RankingTabs({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    initialIndex: context.read<LeaderboardCubit>().state.selectedTab,
    child: _TabSync(child: child),
  );
}

class _TabSync extends StatefulWidget {
  const _TabSync({required this.child});
  final Widget child;
  @override
  State<_TabSync> createState() => _TabSyncState();
}

class _TabSyncState extends State<_TabSync> {
  TabController? _controller;
  StreamSubscription<LeaderboardState>? _subscription;
  void _changed() =>
      context.read<LeaderboardCubit>().selectTab(_controller!.index);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (identical(controller, _controller)) return;
    _controller?.removeListener(_changed);
    _subscription?.cancel();
    _controller = controller..addListener(_changed);
    _subscription = context.read<LeaderboardCubit>().stream.listen((state) {
      if (mounted && controller.index != state.selectedTab) {
        controller.index = state.selectedTab;
      }
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_changed);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
