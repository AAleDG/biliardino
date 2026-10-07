import 'package:flutter/material.dart';

import '../../theme/italia90_tokens.dart';

/// Compact summary of the current history query.
class HistoryFilterSummaryBar extends StatelessWidget {
  const HistoryFilterSummaryBar({
    super.key,
    required this.matchesCount,
    required this.label,
    required this.hasActiveFilters,
    required this.onOpenFilters,
    required this.onReset,
  });

  final int matchesCount;
  final String label;
  final bool hasActiveFilters;
  final VoidCallback onOpenFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final summary = hasActiveFilters ? label : 'Tutti i risultati';
    final count = '$matchesCount ${matchesCount == 1 ? 'partita' : 'partite'}';
    return Material(
      color: Italia90.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Italia90.panelRadius),
        side: BorderSide(
          color: hasActiveFilters ? Italia90.primary : Italia90.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              key: const ValueKey('history-open-filters'),
              container: true,
              button: true,
              label: 'Apri filtri: $summary, $count',
              onTap: onOpenFilters,
              child: InkWell(
                onTap: onOpenFilters,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Italia90.md,
                      vertical: Italia90.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt_outlined,
                          color: Italia90.primary,
                          size: 22,
                        ),
                        const SizedBox(width: Italia90.sm),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final compact =
                                  constraints.maxWidth < 230 ||
                                  MediaQuery.textScalerOf(context).scale(1) >
                                      1.3;
                              final summaryText = Text(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Italia90.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                              final countText = Text(
                                count,
                                style: Italia90.caption.copyWith(
                                  color: Italia90.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                              return compact
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        summaryText,
                                        const SizedBox(height: Italia90.xs),
                                        countText,
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: summaryText),
                                        const SizedBox(width: Italia90.sm),
                                        countText,
                                      ],
                                    );
                            },
                          ),
                        ),
                        const SizedBox(width: Italia90.sm),
                        const Icon(
                          Icons.chevron_right,
                          color: Italia90.primary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasActiveFilters)
            IconButton(
              key: const ValueKey('history-reset-filters'),
              tooltip: 'Reset filtri',
              onPressed: onReset,
              color: Italia90.primary,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}
