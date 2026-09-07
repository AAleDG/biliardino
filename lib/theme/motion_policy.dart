import 'package:flutter/material.dart';

/// Read in build/didChangeDependencies for live MediaQuery updates. Controllers
/// also observe platform accessibility changes through [MotionAwareState].
bool shouldReduceMotion([BuildContext? context]) {
  final features =
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
  return features.disableAnimations ||
      features.reduceMotion ||
      (context != null && MediaQuery.disableAnimationsOf(context));
}

abstract final class AppMotion {
  static const selection = Duration(milliseconds: 180);
  static const navigation = Duration(milliseconds: 220);
  static const score = Duration(milliseconds: 220);
  static const content = Duration(milliseconds: 220);
  static const podium = Duration(milliseconds: 400);
  static const goal = Duration(milliseconds: 1100);
  static const victory = Duration(milliseconds: 500);
  static const confetti = Duration(milliseconds: 2000);
  static const splash = Duration(milliseconds: 1000);
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;

  static Duration duration(BuildContext context, Duration normal) =>
      shouldReduceMotion(context) ? Duration.zero : normal;
}

/// Cancels visual movement when accessibility settings change at runtime.
/// Implementers settle their own controllers; data callbacks are independent.
mixin MotionAwareState<T extends StatefulWidget> on State<T> {
  late final _AccessibilityObserver _motionObserver;
  bool get reduceMotion => shouldReduceMotion(context);

  @override
  void initState() {
    super.initState();
    _motionObserver = _AccessibilityObserver(_accessibilityChanged);
    WidgetsBinding.instance.addObserver(_motionObserver);
  }

  void settleMotion();

  void _accessibilityChanged() {
    if (!mounted) return;
    if (reduceMotion) settleMotion();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion) settleMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_motionObserver);
    super.dispose();
  }
}

class _AccessibilityObserver extends WidgetsBindingObserver {
  _AccessibilityObserver(this.onChanged);
  final VoidCallback onChanged;
  @override
  void didChangeAccessibilityFeatures() => onChanged();
}
