import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubits/history/history_cubit.dart';
import '../cubits/history/history_filters.dart';
import '../cubits/history/history_logic.dart';
import '../cubits/history/history_state.dart';
import '../models/game_match.dart';
import '../models/player.dart';
import '../repositories/match_repository.dart';
import '../repositories/player_repository.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (ctx) => HistoryCubit(
        playerRepository: ctx.read<PlayerRepository>(),
        matchRepository: ctx.read<MatchRepository>(),
      ),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final matches = state.filteredMatches;
        final groups = state.groups;
        final hasActiveFilters = state.hasActiveFilters;

        return Scaffold(
          appBar: AppBar(title: const Text('STORICO')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _HistorySummary(
                  matchesCount: state.matchesCount,
                  lastMatch: state.lastMatchAt,
                  filterLabel: state.filterLabel,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FilterSummaryBar(
                  label: state.filterLabel,
                  hasActiveFilters: hasActiveFilters,
                  onOpenFilters: () => _openFilters(context, state),
                  onReset: context.read<HistoryCubit>().resetFilters,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: matches.isEmpty
                    ? _Empty(
                        isFiltered: hasActiveFilters,
                        filterLabel: state.filterLabel,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: groups.length,
                        itemBuilder: (_, i) => _MatchDaySection(
                          group: groups[i],
                          players: state.players,
                          anim: _ctrl,
                          delay: math.min(i, 8) * 0.08,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _openFilters(BuildContext rootContext, HistoryState state) async {
  final cubit = rootContext.read<HistoryCubit>();
  final selectedFilters = await showModalBottomSheet<HistoryFilters>(
    context: rootContext,
    backgroundColor: NttColors.surfaceMid,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _HistoryFilterSheet(
      players: state.players,
      initialFilters: state.filters,
    ),
  );
  if (selectedFilters == null) {
    return;
  }
  cubit.applyFilters(selectedFilters);
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.matchesCount,
    required this.lastMatch,
    required this.filterLabel,
  });

  final int matchesCount;
  final DateTime? lastMatch;
  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    final lastLabel = lastMatch == null
        ? '-'
        : DateFormat('dd/MM · HH:mm').format(lastMatch!);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: 'Partite',
                value: '$matchesCount',
                icon: Icons.sports_score_outlined,
              ),
            ),
            const _SummaryDivider(),
            Expanded(
              child: _SummaryItem(
                label: 'Ultima',
                value: lastLabel,
                icon: Icons.schedule,
              ),
            ),
            const _SummaryDivider(),
            Expanded(
              child: _SummaryItem(
                label: 'Filtro',
                value: filterLabel,
                icon: Icons.filter_alt_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: NttColors.textFaint),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: NttColors.textFaint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: NttColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _FilterSummaryBar extends StatelessWidget {
  const _FilterSummaryBar({
    required this.label,
    required this.hasActiveFilters,
    required this.onOpenFilters,
    required this.onReset,
  });

  final String label;
  final bool hasActiveFilters;
  final VoidCallback onOpenFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NttColors.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpenFilters,
        child: Container(
          height: 46,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActiveFilters
                  ? NttColors.accent.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tune,
                size: 20,
                color:
                    hasActiveFilters ? NttColors.accent : NttColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NttColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasActiveFilters)
                IconButton(
                  key: const ValueKey('history-reset-filters'),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Reset filtri',
                  icon: const Icon(Icons.close, size: 18),
                  color: NttColors.textMuted,
                  onPressed: onReset,
                ),
              IconButton(
                key: const ValueKey('history-open-filters'),
                visualDensity: VisualDensity.compact,
                tooltip: 'Apri filtri',
                icon: const Icon(Icons.filter_alt_outlined, size: 20),
                color: NttColors.accent,
                onPressed: onOpenFilters,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                  color: Colors.white.withValues(alpha: 0.18),
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
                      color: NttColors.textPrimary,
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
            const _FilterSectionLabel('PERIODO'),
            const SizedBox(height: 8),
            _SegmentedFilter<HistoryPeriod>(
              values: HistoryPeriod.values,
              selectedValue: _draftFilters.period,
              labelForValue: periodLabel,
              onSelected: (period) => setState(
                () => _draftFilters = _draftFilters.copyWith(
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
                  period: _draftFilters.period,
                  playerId: _draftFilters.playerId,
                  result: result,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const ValueKey('history-apply-filters'),
                    onPressed: () => Navigator.of(context).pop(_draftFilters),
                    child: const Text('Applica'),
                  ),
                ),
              ],
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
    return Text(
      text,
      style: const TextStyle(
        color: NttColors.textFaint,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
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
          labelStyle: TextStyle(
            color: selected && enabled
                ? NttColors.surfaceDark
                : NttColors.textPrimary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          ),
          selectedColor: enabled ? NttColors.accent : NttColors.surfaceHigh,
          backgroundColor: NttColors.surfaceHigh,
          disabledColor: NttColors.surfaceHigh.withValues(alpha: 0.45),
          side: BorderSide(
            color: selected && enabled
                ? NttColors.accent
                : Colors.white.withValues(alpha: 0.06),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              labelStyle: TextStyle(
                color: selectedPlayerId == null
                    ? NttColors.surfaceDark
                    : NttColors.textPrimary,
                fontSize: 13,
                fontWeight: selectedPlayerId == null
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
              selectedColor: NttColors.accent,
              backgroundColor: NttColors.surfaceHigh,
              side: BorderSide(
                color: selectedPlayerId == null
                    ? NttColors.accent
                    : Colors.white.withValues(alpha: 0.06),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            ...players.map((player) {
              final selected = selectedPlayerId == player.id;
              return ChoiceChip(
                key: ValueKey('history-player-${player.id}'),
                label: Text(player.name),
                selected: selected,
                onSelected: (_) => onSelected(player.id),
                labelStyle: TextStyle(
                  color:
                      selected ? NttColors.surfaceDark : NttColors.textPrimary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                ),
                selectedColor: NttColors.accent,
                backgroundColor: NttColors.surfaceHigh,
                side: BorderSide(
                  color: selected
                      ? NttColors.accent
                      : Colors.white.withValues(alpha: 0.06),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MatchDaySection extends StatelessWidget {
  const _MatchDaySection({
    required this.group,
    required this.players,
    required this.anim,
    required this.delay,
  });

  final MatchDayGroup group;
  final List<Player> players;
  final Animation<double> anim;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final sectionAnim = CurvedAnimation(
      parent: anim,
      curve: Interval(
        delay,
        math.min(delay + 0.35, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: sectionAnim,
      builder: (_, child) {
        final t = sectionAnim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(dayLabel(group.day, DateTime.now())),
            const SizedBox(height: 6),
            ...group.matches.map(
              (match) => _MatchCard(match: match, players: players),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: NttColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.2,
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.players,
  });

  final GameMatch match;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('HH:mm').format(match.playedAt);
    final t1Names =
        match.team1.map((id) => StatsService.playerName(players, id)).toList();
    final t2Names =
        match.team2.map((id) => StatsService.playerName(players, id)).toList();
    final winColor = match.winningTeam == 1 ? NttColors.team1 : NttColors.team2;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: winColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 13,
                      color: NttColors.textFaint,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: NttColors.textFaint,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TeamResultLine(
                  color: NttColors.team1,
                  names: t1Names,
                  score: match.t1Score,
                  isWinner: match.winningTeam == 1,
                ),
                const SizedBox(height: 6),
                _TeamResultLine(
                  color: NttColors.team2,
                  names: t2Names,
                  score: match.t2Score,
                  isWinner: match.winningTeam == 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamResultLine extends StatelessWidget {
  const _TeamResultLine({
    required this.color,
    required this.names,
    required this.score,
    required this.isWinner,
  });

  final Color color;
  final List<String> names;
  final int score;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isWinner ? 1 : 0.35),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            names.join(' / '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWinner ? NttColors.textPrimary : NttColors.textMuted,
              fontSize: 14,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isWinner) ...[
          Text(
            'Vittoria',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: 28,
          child: Text(
            '$score',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isWinner ? color : NttColors.textFaint,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.isFiltered, required this.filterLabel});

  final bool isFiltered;
  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    final title = isFiltered ? 'Nessuna partita trovata' : 'Nessuna partita';
    final subtitle = isFiltered
        ? 'Cambia filtro per consultare altri risultati.'
        : 'Registra una partita per popolare lo storico.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 56, color: NttColors.textFaint),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NttColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: NttColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
