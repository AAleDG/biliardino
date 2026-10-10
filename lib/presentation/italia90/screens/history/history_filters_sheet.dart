import 'package:flutter/material.dart';

import '../../../../cubits/history/history_filters.dart';
import '../../../../models/player.dart';
import '../../theme/italia90_tokens.dart';
import '../../widgets/design/adaptive_pair.dart';

/// Stateful draft editor for history filters.
class HistoryFiltersSheet extends StatefulWidget {
  const HistoryFiltersSheet({
    super.key,
    required this.players,
    required this.initialFilters,
  });

  final List<Player> players;
  final HistoryFilters initialFilters;

  @override
  State<HistoryFiltersSheet> createState() => _HistoryFiltersSheetState();
}

class _HistoryFiltersSheetState extends State<HistoryFiltersSheet> {
  late HistoryFilters _draftFilters;

  @override
  void initState() {
    super.initState();
    _draftFilters = widget.initialFilters;
  }

  void _update({
    HistoryMatchModeFilter? matchMode,
    HistoryPeriod? period,
    Object? playerId = _unchanged,
    HistoryResult? result,
  }) {
    final nextPlayerId = identical(playerId, _unchanged)
        ? _draftFilters.playerId
        : playerId as String?;
    setState(() {
      _draftFilters = _draftFilters.copyWith(
        matchMode: matchMode ?? _draftFilters.matchMode,
        period: period ?? _draftFilters.period,
        playerId: nextPlayerId,
        result: result ?? _draftFilters.result,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Italia90.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text('Filtri storico', style: Italia90.heading),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _draftFilters = _draftFilters.reset()),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _HistoryFilterLabel('FORMATO'),
            const SizedBox(height: 8),
            _HistorySegmentedFilter<HistoryMatchModeFilter>(
              values: HistoryMatchModeFilter.values,
              selectedValue: _draftFilters.matchMode,
              labelForValue: matchModeLabel,
              onSelected: (value) => _update(matchMode: value),
            ),
            const SizedBox(height: 12),
            const _HistoryFilterLabel('PERIODO'),
            const SizedBox(height: 8),
            _HistorySegmentedFilter<HistoryPeriod>(
              values: HistoryPeriod.values,
              selectedValue: _draftFilters.period,
              labelForValue: periodLabel,
              onSelected: (value) => _update(period: value),
            ),
            const SizedBox(height: 12),
            const _HistoryFilterLabel('GIOCATORE'),
            const SizedBox(height: 8),
            _HistoryPlayerSelector(
              players: widget.players,
              selectedPlayerId: _draftFilters.playerId,
              onSelected: (value) => _update(playerId: value),
            ),
            const SizedBox(height: 12),
            const _HistoryFilterLabel('RISULTATO'),
            const SizedBox(height: 8),
            _HistorySegmentedFilter<HistoryResult>(
              values: HistoryResult.values,
              selectedValue: _draftFilters.result,
              enabled: _draftFilters.playerId != null,
              labelForValue: resultLabel,
              onSelected: (value) => _update(result: value),
            ),
            const SizedBox(height: 20),
            AdaptivePair(
              first: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              second: ElevatedButton(
                key: const ValueKey('history-apply-filters'),
                onPressed: () => Navigator.of(context).pop(_draftFilters),
                child: const Text('Applica'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _unchanged = Object();

class _HistoryFilterLabel extends StatelessWidget {
  const _HistoryFilterLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: Italia90.caption.copyWith(
        color: Italia90.muted,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    ),
  );
}

class _HistorySegmentedFilter<T> extends StatelessWidget {
  const _HistorySegmentedFilter({
    required this.values,
    required this.selectedValue,
    required this.labelForValue,
    required this.onSelected,
    this.enabled = true,
  });

  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelForValue;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = _segmentedFilterColumns(
        values.length,
        constraints.maxWidth,
        MediaQuery.textScalerOf(context).scale(1),
      );
      final width = _filterChipWidth(constraints.maxWidth, columns);
      return Wrap(
        spacing: Italia90.sm,
        runSpacing: Italia90.sm,
        children: [
          for (final value in values)
            _HistoryFilterChip(
              chipKey: ValueKey(
                'history-filter-${value.toString().split('.').last}',
              ),
              label: labelForValue(value),
              width: width,
              selected: value == selectedValue,
              enabled: enabled,
              onSelected: () => onSelected(value),
            ),
        ],
      );
    },
  );
}

class _HistoryPlayerSelector extends StatelessWidget {
  const _HistoryPlayerSelector({
    required this.players,
    required this.selectedPlayerId,
    required this.onSelected,
  });

  final List<Player> players;
  final String? selectedPlayerId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final columns = textScale > 1.3
          ? 1
          : constraints.maxWidth >= 340
          ? 3
          : 2;
      final width = _filterChipWidth(constraints.maxWidth, columns);
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 112),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: Italia90.sm,
            runSpacing: Italia90.sm,
            children: [
              _HistoryFilterChip(
                chipKey: const ValueKey('history-player-all'),
                label: 'Tutti',
                width: width,
                selected: selectedPlayerId == null,
                onSelected: () => onSelected(null),
              ),
              for (final player in players)
                _HistoryFilterChip(
                  chipKey: ValueKey('history-player-${player.id}'),
                  label: player.name,
                  width: width,
                  selected: selectedPlayerId == player.id,
                  onSelected: () => onSelected(player.id),
                ),
            ],
          ),
        ),
      );
    },
  );
}

int _segmentedFilterColumns(
  int itemCount,
  double availableWidth,
  double textScale,
) {
  if (textScale > 1.3) {
    return 1;
  }
  if (itemCount == 3 && availableWidth >= 340) {
    return 3;
  }
  return 2;
}

double _filterChipWidth(double availableWidth, int columns) {
  final gaps = Italia90.sm * (columns - 1);
  return (availableWidth - gaps) / columns;
}

double _historyFilterChipHeight(BuildContext context) {
  final textScaler = MediaQuery.textScalerOf(context);
  final fontSize = Italia90.body.fontSize ?? 16;
  final lineHeight = textScaler.scale(fontSize) * (Italia90.body.height ?? 1);
  final textScale = textScaler.scale(1);
  final accessibilityPadding = textScale > 1.3 ? Italia90.sm : 0;
  final preferredHeight = lineHeight + accessibilityPadding;
  return preferredHeight > Italia90.touch ? preferredHeight : Italia90.touch;
}

class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.chipKey,
    required this.label,
    required this.width,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final Key chipKey;
  final String label;
  final double width;
  final bool selected;
  final VoidCallback onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selectedAndEnabled = selected && enabled;
    final height = _historyFilterChipHeight(context);
    final backgroundColor = selected
        ? Italia90.primary
        : enabled
        ? Italia90.subtle
        : Italia90.subtle.withValues(alpha: 0.45);
    final foregroundColor = selectedAndEnabled
        ? Colors.white
        : enabled
        ? Italia90.ink
        : Italia90.muted;

    return SizedBox(
      key: chipKey,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: label,
        excludeSemantics: true,
        onTap: enabled ? onSelected : null,
        child: Material(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Italia90.controlRadius),
            side: const BorderSide(color: Italia90.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onSelected : null,
            child: SizedBox.expand(
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Italia90.body.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
