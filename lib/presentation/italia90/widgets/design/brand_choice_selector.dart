import '../../../../widgets/selection_motion.dart';
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

/// Shared accessible selector for format and ranking choices.
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
            style: AppType.action.copyWith(fontSize: 24),
          ),
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
        )..layout();
        if (painter.width + 24 > choiceWidth) {
          choiceWidth = painter.width + 24;
        }
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
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: SelectionShape.borderRadius,
              ),
            ),
          ),
          Row(
            children: [
              for (var index = 0; index < choices.length; index++)
                Expanded(child: _choice(choices[index])),
            ],
          ),
        ],
      );
      return Container(
        height: (MediaQuery.textScalerOf(context).scale(24) * 1.1 + 8).clamp(
          56.0,
          double.infinity,
        ),
        padding: const EdgeInsets.all(1),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: SelectionShape.borderRadius,
          border: Border.all(color: AppColors.outline),
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

  Widget _choice(BrandChoice<T> choice) {
    final active = choice.value == selected;
    final onTap = onChanged == null ? null : () => onChanged!(choice.value);
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
          borderRadius: SelectionShape.borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: SelectionShape.borderRadius,
            child: Center(
              child: Text(
                choice.label,
                style: AppType.action.copyWith(
                  color: active ? AppColors.onPrimary : AppColors.ink,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
