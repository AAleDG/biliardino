import '../selection_motion.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BrandChoice<T> {
  const BrandChoice({
    required this.value,
    required this.label,
    this.semanticLabel,
    this.semanticKey,
  });
  final T value;
  final String label;
  final String? semanticLabel;
  final Key? semanticKey;
}

/// Shared pill selector for setup modes and ranking views.
class BrandChoiceSelector<T> extends StatelessWidget {
  const BrandChoiceSelector({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
  });
  final List<BrandChoice<T>> choices;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      var choiceWidth = 0.0;
      for (final word in choices.expand((choice) => choice.label.split(' '))) {
        final painter = TextPainter(
          text: TextSpan(
            text: word,
            style: AppType.action.copyWith(fontSize: 28),
          ),
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
        )..layout();
        if (painter.width + 24 > choiceWidth) choiceWidth = painter.width + 24;
        painter.dispose();
      }
      final width = (choiceWidth * choices.length).clamp(
        constraints.maxWidth - 4,
        double.infinity,
      );
      final row = Stack(
        children: [
          Positioned.fill(
            child: SlidingSelection(
              index: choices.indexWhere((choice) => choice.value == selected),
              count: choices.length,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(
                    selected == choices.first.value ? 28 : 16,
                  ),
                  right: Radius.circular(
                    selected == choices.last.value ? 28 : 16,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var index = 0; index < choices.length; index++)
                Expanded(child: _choice(choices[index], index)),
            ],
          ),
        ],
      );
      return Container(
        height: (MediaQuery.textScalerOf(context).scale(28) * 1.1 + 8).clamp(
          58.0,
          double.infinity,
        ),
        padding: const EdgeInsets.all(1),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.divider),
        ),
        child: width <= constraints.maxWidth - 4
            ? row
            : ScrollableSelection(
                index: choices.indexWhere((choice) => choice.value == selected),
                count: choices.length,
                width: width,
                child: row,
              ),
      );
    },
  );

  Widget _choice(BrandChoice<T> choice, int index) {
    final active = choice.value == selected;
    final onTap = onChanged == null ? null : () => onChanged!(choice.value);
    final radius = BorderRadius.horizontal(
      left: Radius.circular(index == 0 ? 28 : 16),
      right: Radius.circular(index == choices.length - 1 ? 28 : 16),
    );
    return Semantics(
      key: choice.semanticKey,
      container: true,
      button: true,
      enabled: onTap != null,
      selected: active,
      inMutuallyExclusiveGroup: true,
      label: choice.semanticLabel ?? choice.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Center(
              child: Text(
                choice.label,
                style: AppType.action.copyWith(
                  color: active ? AppColors.onPrimary : AppColors.ink,
                  fontSize: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
