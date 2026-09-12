part of '../history_screen.dart';

class _FilterSummaryBar extends StatelessWidget {
  const _FilterSummaryBar({
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
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        side: BorderSide(
          color: hasActiveFilters ? AppColors.primary : AppColors.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Apri filtri: $summary, $count',
              child: InkWell(
                key: const ValueKey('history-open-filters'),
                onTap: onOpenFilters,
                child: ExcludeSemantics(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSpace.touch,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.medium,
                        vertical: AppSpace.small,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_alt_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpace.small),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow =
                                    constraints.maxWidth < 230 ||
                                    MediaQuery.textScalerOf(context).scale(1) >
                                        1.3;
                                final summaryText = Text(
                                  summary,
                                  style: AppType.bodyStrong,
                                );
                                final countText = Text(
                                  count,
                                  style: AppType.utility.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                );
                                return narrow
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          summaryText,
                                          const SizedBox(
                                            height: AppSpace.micro,
                                          ),
                                          countText,
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: summaryText),
                                          const SizedBox(width: AppSpace.small),
                                          countText,
                                        ],
                                      );
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpace.small),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ],
                      ),
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
              color: AppColors.primary,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}
