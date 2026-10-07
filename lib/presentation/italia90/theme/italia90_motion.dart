import 'package:flutter/material.dart';

abstract final class Italia90Motion {
  static const selection = Duration(milliseconds: 160);
  static const score = Duration(milliseconds: 200);
  static const goal = Duration(milliseconds: 800);
  static const matchWave = Duration(milliseconds: 2400);
  static const victory = Duration(milliseconds: 320);
  static const victoryCelebration = Duration(milliseconds: 3000);
  static const confetti = Duration(milliseconds: 1200);
  static const splash = Duration(milliseconds: 800);
  static const navigation = Duration(milliseconds: 180);
  static const curve = Curves.easeOutCubic;

  static bool reducedOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_MotionPolicy>();
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return (scope?.reduced ??
            (features.disableAnimations || features.reduceMotion)) ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  static Duration durationOf(BuildContext context, Duration duration) =>
      reducedOf(context) ? Duration.zero : duration;
}

/// Observes both platform accessibility flags, including changes while mounted.
/// Place above MaterialApp; descendants also respect their local MediaQuery.
class Italia90MotionScope extends StatefulWidget {
  const Italia90MotionScope({super.key, required this.child, this.reduced});
  final Widget child;

  /// Development preview override; omitted by the production app.
  final bool? reduced;

  @override
  State<Italia90MotionScope> createState() => _Italia90MotionScopeState();
}

class _Italia90MotionScopeState extends State<Italia90MotionScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return _MotionPolicy(
      reduced:
          widget.reduced ??
          (features.disableAnimations || features.reduceMotion),
      child: widget.child,
    );
  }
}

class _MotionPolicy extends InheritedWidget {
  const _MotionPolicy({required this.reduced, required super.child});
  final bool reduced;
  @override
  bool updateShouldNotify(_MotionPolicy oldWidget) =>
      reduced != oldWidget.reduced;
}
