part of '../history_screen.dart';

class _HistoryFilterSheet extends StatefulWidget {
  const _HistoryFilterSheet({
    required this.players,
    required this.initialFilters,
  });

  final List<Player> players;
  final HistoryFilters initialFilters;

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late HistoryFilters _draftFilters;

  @override
  void initState() {
    super.initState();
    _draftFilters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

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
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtri storico',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _draftFilters = _draftFilters.reset()),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _FilterSectionLabel('FORMATO'),
            const SizedBox(height: 8),
            _SegmentedFilter<HistoryMatchModeFilter>(
              values: HistoryMatchModeFilter.values,
              selectedValue: _draftFilters.matchMode,
              labelForValue: matchModeLabel,
              onSelected: (matchMode) => setState(
                () => _draftFilters = _draftFilters.copyWith(
                  matchMode: matchMode,
                  period: _draftFilters.period,
                  playerId: _draftFilters.playerId,
                  result: _draftFilters.result,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _FilterSectionLabel('PERIODO'),
            const SizedBox(height: 8),
            _SegmentedFilter<HistoryPeriod>(
              values: HistoryPeriod.values,
              selectedValue: _draftFilters.period,
              labelForValue: periodLabel,
              onSelected: (period) => setState(
                () => _draftFilters = _draftFilters.copyWith(
                  matchMode: _draftFilters.matchMode,
                  period: period,
                  playerId: _draftFilters.playerId,
                  result: _draftFilters.result,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _FilterSectionLabel('GIOCATORE'),
            const SizedBox(height: 8),
            _PlayerSelector(
              players: widget.players,
              selectedPlayerId: _draftFilters.playerId,
              onSelected: (playerId) => setState(
                () => _draftFilters = _draftFilters.copyWith(
                  matchMode: _draftFilters.matchMode,
                  period: _draftFilters.period,
                  playerId: playerId,
                  result: _draftFilters.result,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _FilterSectionLabel('RISULTATO'),
            const SizedBox(height: 8),
            _SegmentedFilter<HistoryResult>(
              values: HistoryResult.values,
              selectedValue: _draftFilters.result,
              enabled: _draftFilters.playerId != null,
              labelForValue: resultLabel,
              onSelected: (result) => setState(
                () => _draftFilters = _draftFilters.copyWith(
                  matchMode: _draftFilters.matchMode,
                  period: _draftFilters.period,
                  playerId: _draftFilters.playerId,
                  result: result,
                ),
              ),
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

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _SegmentedFilter<T> extends StatelessWidget {
  const _SegmentedFilter({
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
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final selected = value == selectedValue;
        final valueKey = value.toString().split('.').last;
        return ChoiceChip(
          key: ValueKey('history-filter-$valueKey'),
          label: Text(labelForValue(value)),
          selected: selected,
          onSelected: enabled ? (_) => onSelected(value) : null,
        );
      }).toList(),
    );
  }
}

class _PlayerSelector extends StatelessWidget {
  const _PlayerSelector({
    required this.players,
    required this.selectedPlayerId,
    required this.onSelected,
  });

  final List<Player> players;
  final String? selectedPlayerId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 168),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('history-player-all'),
              label: const Text('Tutti'),
              selected: selectedPlayerId == null,
              onSelected: (_) => onSelected(null),
            ),
            ...players.map((player) {
              final selected = selectedPlayerId == player.id;
              return ChoiceChip(
                key: ValueKey('history-player-${player.id}'),
                label: Text(player.name),
                selected: selected,
                onSelected: (_) => onSelected(player.id),
              );
            }),
          ],
        ),
      ),
    );
  }
}
