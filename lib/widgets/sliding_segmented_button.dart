import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'selection_motion.dart';

/// Native segment semantics, focus and callbacks with a single moving fill.
/// Used for mutually exclusive modes; filters retain their independent chips.
class SlidingSegmentedButton<T> extends StatelessWidget {
  const SlidingSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.style,
    this.expandedInsets,
    this.showSelectedIcon = true,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final ButtonStyle? style;
  final EdgeInsetsGeometry? expandedInsets;
  final bool showSelectedIcon;

  @override
  Widget build(BuildContext context) {
    assert(selected.length == 1);
    final theme = Theme.of(context);
    final effective =
        style?.merge(SegmentedButtonTheme.of(context).style) ??
        SegmentedButtonTheme.of(context).style ??
        const ButtonStyle();
    final disabled = onSelectionChanged == null;
    final states = <WidgetState>{if (disabled) WidgetState.disabled};
    final selectedStates = {...states, WidgetState.selected};
    const shape = SelectionShape.border;
    final outline =
        effective.side?.resolve(states) ??
        BorderSide(color: theme.colorScheme.outline);
    final background =
        effective.backgroundColor?.resolve(states) ?? theme.colorScheme.surface;
    final fill =
        effective.backgroundColor?.resolve(selectedStates) ??
        (disabled
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primary);
    final foreground =
        effective.foregroundColor ??
        WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.disabled)
              ? theme.colorScheme.onSurface.withValues(alpha: .38)
              : states.contains(WidgetState.selected)
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        );
    final padding =
        (effective.padding?.resolve(states) ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8))
            .resolve(Directionality.of(context));
    final fontSize = effective.textStyle?.resolve(states)?.fontSize ?? 20;
    // Keep a 48dp visual/touch target, including compact ranking selectors.
    final verticalPadding = math.max(padding.vertical / 2, (48 - fontSize) / 2);
    final index = segments.indexWhere(
      (segment) => selected.contains(segment.value),
    );
    return Padding(
      padding: expandedInsets ?? EdgeInsets.zero,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(shape: shape.copyWith(side: outline)),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: background,
                  shape: shape.copyWith(side: BorderSide.none),
                ),
                child: SlidingSelection(
                  index: index,
                  count: segments.length,
                  decoration: ShapeDecoration(
                    color: fill,
                    shape: shape.copyWith(side: BorderSide.none),
                  ),
                ),
              ),
            ),
            SegmentedButton<T>(
              segments: segments,
              selected: selected,
              onSelectionChanged: onSelectionChanged,
              expandedInsets: expandedInsets == null ? null : EdgeInsets.zero,
              showSelectedIcon: showSelectedIcon,
              style: effective.copyWith(
                // Flutter uses side for both the perimeter and inner dividers.
                // Draw the perimeter once above the control instead.
                side: const WidgetStatePropertyAll(BorderSide.none),
                shape: const WidgetStatePropertyAll(shape),
                backgroundColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                foregroundColor: foreground,
                animationDuration: Duration.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.standard,
                padding: WidgetStatePropertyAll(
                  padding.copyWith(
                    top: verticalPadding,
                    bottom: verticalPadding,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
