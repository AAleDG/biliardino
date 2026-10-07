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
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final value in values)
        ChoiceChip(
          key: ValueKey('history-filter-${value.toString().split('.').last}'),
          label: Text(labelForValue(value)),
          selected: value == selectedValue,
          onSelected: enabled ? (_) => onSelected(value) : null,
          selectedColor: Italia90.primary,
          backgroundColor: Italia90.subtle,
          disabledColor: Italia90.subtle.withValues(alpha: 0.45),
          labelStyle: TextStyle(
            color: value == selectedValue && enabled
                ? Colors.white
                : Italia90.ink,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Italia90.controlRadius),
          ),
        ),
    ],
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
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 112),
    child: SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip(
            key: const ValueKey('history-player-all'),
            label: 'Tutti',
            selected: selectedPlayerId == null,
            onSelected: () => onSelected(null),
          ),
          for (final player in players)
            _chip(
              key: ValueKey('history-player-${player.id}'),
              label: player.name,
              selected: selectedPlayerId == player.id,
              onSelected: () => onSelected(player.id),
            ),
        ],
      ),
    ),
  );

  Widget _chip({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) => ChoiceChip(
    key: key,
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
    selectedColor: Italia90.primary,
    backgroundColor: Italia90.subtle,
    labelStyle: TextStyle(
      color: selected ? Colors.white : Italia90.ink,
      fontWeight: FontWeight.w700,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Italia90.controlRadius),
    ),
  );
}
