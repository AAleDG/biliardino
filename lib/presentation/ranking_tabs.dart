import 'dart:async';
import '../widgets/selection_motion.dart';
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
    animationDuration: Duration.zero,
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

/// Retains the native swipe gesture and both pane states. Tapped selections
/// jump to the current pane and fade in rather than sliding stale rankings.
class RankingTabView extends StatelessWidget {
  const RankingTabView({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LeaderboardCubit, LeaderboardState>(
        buildWhen: (previous, current) =>
            previous.selectedTab != current.selectedTab ||
            previous.selectedMode != current.selectedMode,
        builder: (context, state) => SelectionFade(
          selection: (state.selectedTab, state.selectedMode),
          child: TabBarView(children: children),
        ),
      );
}

/// Shared ranking hierarchy and spacing; each presentation supplies its skin.
class RankingSelectors extends StatelessWidget {
  const RankingSelectors({
    super.key,
    required this.modeSelector,
    required this.tabSelector,
    required this.horizontalPadding,
  });
  final Widget modeSelector;
  final Widget tabSelector;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.textScalerOf(context).scale(16) > 22
                  ? 320
                  : 236,
            ),
            child: modeSelector,
          ),
        ),
        const SizedBox(height: 12),
        tabSelector,
      ],
    ),
  );
}
