import 'package:flutter/material.dart';

import '../theme/motion_policy.dart';

/// The shared timing for tab and segmented-selection feedback in both styles.
abstract final class SelectionMotion {
  static const duration = Duration(milliseconds: 180);
  static const curve = Curves.easeInOut;
}

/// One moving fill beneath persistent, immediately updated choice labels.
class SlidingSelection extends StatefulWidget {
  const SlidingSelection({
    super.key,
    required this.index,
    required this.count,
    required this.decoration,
    this.vertical = false,
    this.inset = EdgeInsets.zero,
  });

  final int index;
  final int count;
  final Decoration decoration;
  final bool vertical;
  final EdgeInsetsGeometry inset;

  @override
  State<SlidingSelection> createState() => _SlidingSelectionState();
}

class _SlidingSelectionState extends State<SlidingSelection>
    with MotionAwareState {
  @override
  // Rebuilding with a new decorative key settles an in-flight implicit tween.
  void settleMotion() {}

  @override
  Widget build(BuildContext context) {
    final position = widget.count <= 1
        ? 0.0
        : -1.0 + 2.0 * widget.index / (widget.count - 1);
    final motionDisabled =
        reduceMotion || !TickerMode.valuesOf(context).enabled;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedAlign(
          key: ValueKey(motionDisabled),
          duration: motionDisabled ? Duration.zero : SelectionMotion.duration,
          curve: SelectionMotion.curve,
          alignment: widget.vertical
              ? Alignment(0, position)
              : AlignmentDirectional(position, 0),
          child: FractionallySizedBox(
            widthFactor: widget.vertical ? 1 : 1 / widget.count,
            heightFactor: widget.vertical ? 1 / widget.count : 1,
            child: Padding(
              padding: widget.inset,
              child: DecoratedBox(decoration: widget.decoration),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reveals only the current content, keeping its element/state tree intact.
/// There is no outgoing, stale page underneath and no delayed data mutation.
class SelectionFade extends StatefulWidget {
  const SelectionFade({
    super.key,
    required this.selection,
    required this.child,
  });

  final Object selection;
  final Widget child;

  @override
  State<SelectionFade> createState() => _SelectionFadeState();
}

class _SelectionFadeState extends State<SelectionFade>
    with SingleTickerProviderStateMixin, MotionAwareState {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SelectionMotion.duration,
    value: 1,
  );
  late final Animation<double> _opacity = _controller.drive(
    CurveTween(curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) settleMotion();
  }

  @override
  void didUpdateWidget(SelectionFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      if (reduceMotion || !TickerMode.valuesOf(context).enabled) {
        settleMotion();
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void settleMotion() => _controller.value = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    alwaysIncludeSemantics: true,
    child: widget.child,
  );
}

/// The existing short top rule follows the same slot as the selected icon.
class NavigationSelectionIndicator extends StatelessWidget {
  const NavigationSelectionIndicator({
    super.key,
    required this.index,
    required this.count,
    required this.color,
  });
  final int index;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 3,
    child: LayoutBuilder(
      builder: (context, constraints) => SlidingSelection(
        index: index,
        count: count,
        inset: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth / count * .30,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

/// Keeps the indicator mounted when enlarged labels require horizontal scroll.
class ScrollableSelection extends StatefulWidget {
  const ScrollableSelection({
    super.key,
    required this.index,
    required this.count,
    required this.width,
    required this.child,
  });
  final int index;
  final int count;
  final double width;
  final Widget child;

  @override
  State<ScrollableSelection> createState() => _ScrollableSelectionState();
}

class _ScrollableSelectionState extends State<ScrollableSelection>
    with MotionAwareState {
  final _scroll = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(ScrollableSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.width != widget.width) {
      _scheduleReveal();
    }
  }

  @override
  void settleMotion() => _scheduleReveal();

  void _scheduleReveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (shouldReduceMotion(context) && position.isScrollingNotifier.value) {
      _scroll.jumpTo(position.pixels);
    }
    final start = widget.width / widget.count * widget.index;
    final end = start + widget.width / widget.count;
    final target =
        (start < position.pixels
                ? start
                : end > position.pixels + position.viewportDimension
                ? end - position.viewportDimension
                : position.pixels)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target != position.pixels) {
      if (shouldReduceMotion(context)) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: SelectionMotion.duration,
          curve: SelectionMotion.curve,
        );
      }
    }
  });

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _scroll,
    scrollDirection: Axis.horizontal,
    child: SizedBox(width: widget.width, child: widget.child),
  );
}
