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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _FilterSummaryBar(
                  matchesCount: state.matchesCount,
                  label: state.filterLabel,
                  hasActiveFilters: hasActiveFilters,
                  onOpenFilters: () => _openFilters(context, state),
                  onReset: context.read<HistoryCubit>().resetFilters,
                ),
              ),
              const SizedBox(height: 10),
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
                          onOpen: (match) => _openMatchDetails(context, match),
                          onEdit: (match) =>
                              _openEditMatchDialog(context, match),
                          onDelete: (match) =>
                              _confirmDeleteMatch(context, match),
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

Future<void> _openMatchDetails(
  BuildContext rootContext,
  GameMatch match,
) async {
  final state = rootContext.read<HistoryCubit>().state;
  final action = await showModalBottomSheet<_MatchAction>(
    context: rootContext,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: NttColors.surfaceMid,
    builder: (context) => _MatchDetailsSheet(
      match: match,
      players: state.players,
    ),
  );
  if (action == null || !rootContext.mounted) {
    return;
  }
  switch (action) {
    case _MatchAction.edit:
      await _openEditMatchDialog(rootContext, match);
    case _MatchAction.delete:
      await _confirmDeleteMatch(rootContext, match);
  }
}

Future<void> _openEditMatchDialog(
  BuildContext rootContext,
  GameMatch match,
) async {
  final cubit = rootContext.read<HistoryCubit>();
  final state = cubit.state;
  final updatedMatch = await showDialog<GameMatch>(
    context: rootContext,
    builder: (dialogContext) =>
        _EditMatchDialog(match: match, players: state.players),
  );
  if (updatedMatch == null || !rootContext.mounted) {
    return;
  }
  try {
    await cubit.updateMatch(updatedMatch);
  } on Object {
    if (rootContext.mounted) {
      _showHistoryMessage(rootContext, 'Impossibile modificare la partita.');
    }
  }
}

Future<void> _confirmDeleteMatch(
  BuildContext rootContext,
  GameMatch match,
) async {
  final confirmed = await showDialog<bool>(
    context: rootContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminare partita?'),
      content: const Text('La partita verra rimossa dallo storico.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
  if (confirmed != true || !rootContext.mounted) {
    return;
  }
  try {
    await rootContext.read<HistoryCubit>().deleteMatch(match);
  } on Object {
    if (rootContext.mounted) {
      _showHistoryMessage(rootContext, 'Impossibile eliminare la partita.');
    }
  }
}

void _showHistoryMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _EditMatchDialog extends StatefulWidget {
  const _EditMatchDialog({required this.match, required this.players});

  final GameMatch match;
  final List<Player> players;

  @override
  State<_EditMatchDialog> createState() => _EditMatchDialogState();
}

class _EditMatchDialogState extends State<_EditMatchDialog> {
  late MatchMode _mode;
  late DateTime _playedAt;
  late bool _isRivalry;
  late List<String> _team1;
  late List<String> _team2;
  late List<String?> _team1Scorers;
  late List<String?> _team2Scorers;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _score1Controller;
  late final TextEditingController _score2Controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mode = widget.match.mode;
    _playedAt = widget.match.playedAt;
    _isRivalry = widget.match.isRivalry;
    _team1 = List<String>.from(widget.match.team1);
    _team2 = List<String>.from(widget.match.team2);
    _team1Scorers = _scorersForTeam(widget.match, widget.match.team1);
    _team2Scorers = _scorersForTeam(widget.match, widget.match.team2);
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_playedAt),
    );
    _timeController = TextEditingController(
      text: DateFormat('HH:mm').format(_playedAt),
    );
    _score1Controller = TextEditingController(text: '${widget.match.t1Score}');
    _score2Controller = TextEditingController(text: '${widget.match.t2Score}');
    _resizeScorers();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _score1Controller.dispose();
    _score2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Correggi partita'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<MatchMode>(
                segments: const [
                  ButtonSegment<MatchMode>(
                    value: MatchMode.oneVsOne,
                    label: Text('1v1'),
                  ),
                  ButtonSegment<MatchMode>(
                    value: MatchMode.twoVsTwo,
                    label: Text('2v2'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selected) => setState(() {
                  _mode = selected.first;
                  _fitTeamsToMode();
                  _resizeScorers();
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Data gg/mm/aaaa',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 112,
                    child: TextField(
                      controller: _timeController,
                      decoration: const InputDecoration(labelText: 'Ora'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TeamEditor(
                title: 'Squadra 1',
                players: widget.players,
                selectedIds: _team1,
                blockedIds: _team2.toSet(),
                teamSize: _mode.teamSize,
                onChanged: (ids) => setState(() {
                  _team1 = ids;
                  _sanitizeScorers();
                }),
              ),
              const SizedBox(height: 12),
              _TeamEditor(
                title: 'Squadra 2',
                players: widget.players,
                selectedIds: _team2,
                blockedIds: _team1.toSet(),
                teamSize: _mode.teamSize,
                onChanged: (ids) => setState(() {
                  _team2 = ids;
                  _sanitizeScorers();
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _score1Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Score squadra 1',
                      ),
                      onChanged: (_) => setState(_resizeScorers),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _score2Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Score squadra 2',
                      ),
                      onChanged: (_) => setState(_resizeScorers),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rivalita'),
                value: _isRivalry,
                onChanged: (value) => setState(() => _isRivalry = value),
              ),
              _ScorersEditor(
                title: 'Marcatori squadra 1',
                teamIds: _team1,
                players: widget.players,
                scorerIds: _team1Scorers,
                onChanged: (index, playerId) => setState(() {
                  _team1Scorers[index] = playerId;
                }),
              ),
              _ScorersEditor(
                title: 'Marcatori squadra 2',
                teamIds: _team2,
                players: widget.players,
                scorerIds: _team2Scorers,
                onChanged: (index, playerId) => setState(() {
                  _team2Scorers[index] = playerId;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: NttColors.warning)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Salva')),
      ],
    );
  }

  void _submit() {
    final score1 = int.tryParse(_score1Controller.text.trim());
    final score2 = int.tryParse(_score2Controller.text.trim());
    final playedAt = _parsePlayedAt();
    final validationError = _validationError(score1, score2, playedAt);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    final normalizedTeam1 = _normalizedTeam(_team1);
    final normalizedTeam2 = _normalizedTeam(_team2);
    final match = widget.match.copyWith(
      playedAt: playedAt,
      mode: _mode,
      t1p1: normalizedTeam1[0],
      t1p2: _mode == MatchMode.twoVsTwo ? normalizedTeam1[1] : '',
      t2p1: normalizedTeam2[0],
      t2p2: _mode == MatchMode.twoVsTwo ? normalizedTeam2[1] : '',
      t1Score: score1,
      t2Score: score2,
      winningTeam: score1! > score2! ? 1 : 2,
      isRivalry: _isRivalry,
      scorerIds: List.unmodifiable(
        [..._team1Scorers, ..._team2Scorers].whereType<String>(),
      ),
    );
    Navigator.of(context).pop(match);
  }

  String? _validationError(int? score1, int? score2, DateTime? playedAt) {
    if (playedAt == null) {
      return 'Inserisci data e ora valide.';
    }
    if (score1 == null || score2 == null || score1 < 0 || score2 < 0) {
      return 'Inserisci punteggi validi.';
    }
    if (score1 == score2) {
      return 'La partita deve avere un vincitore.';
    }
    if (_normalizedTeam(_team1).length != _mode.teamSize ||
        _normalizedTeam(_team2).length != _mode.teamSize) {
      return 'Completa entrambe le squadre.';
    }
    final playerIds = [..._normalizedTeam(_team1), ..._normalizedTeam(_team2)];
    if (playerIds.toSet().length != _mode.teamSize * 2) {
      return 'Ogni giocatore puo stare in una sola squadra.';
    }
    if (_team1Scorers.length != score1 || _team2Scorers.length != score2) {
      return 'Il numero di marcatori deve corrispondere allo score.';
    }
    if (_team1Scorers.any((id) => id == null) ||
        _team2Scorers.any((id) => id == null)) {
      return 'Assegna tutti i marcatori prima di salvare.';
    }
    if (!_team1Scorers.every(_team1.contains) ||
        !_team2Scorers.every(_team2.contains)) {
      return 'Ogni marcatore deve appartenere alla propria squadra.';
    }
    return null;
  }

  DateTime? _parsePlayedAt() {
    try {
      final date = DateFormat(
        'dd/MM/yyyy',
      ).parseStrict(_dateController.text.trim());
      final time = DateFormat('HH:mm').parseStrict(_timeController.text.trim());
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } on FormatException {
      return null;
    }
  }

  void _fitTeamsToMode() {
    _team1 = _normalizedTeam(_team1).take(_mode.teamSize).toList();
    _team2 = _normalizedTeam(_team2).take(_mode.teamSize).toList();
  }

  void _resizeScorers() {
    _fitTeamScorers(_team1Scorers, _team1, _currentScore(_score1Controller));
    _fitTeamScorers(_team2Scorers, _team2, _currentScore(_score2Controller));
  }

  void _sanitizeScorers() {
    _team1Scorers = _team1Scorers
        .map((id) => id == null || _team1.contains(id) ? id : null)
        .toList();
    _team2Scorers = _team2Scorers
        .map((id) => id == null || _team2.contains(id) ? id : null)
        .toList();
    _resizeScorers();
  }
}

class _TeamEditor extends StatelessWidget {
  const _TeamEditor({
    required this.title,
    required this.players,
    required this.selectedIds,
    required this.blockedIds,
    required this.teamSize,
    required this.onChanged,
  });

  final String title;
  final List<Player> players;
  final List<String> selectedIds;
  final Set<String> blockedIds;
  final int teamSize;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterSectionLabel(title),
        const SizedBox(height: 6),
        ...List.generate(teamSize, (index) {
          final selectedId = index < selectedIds.length
              ? selectedIds[index]
              : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButtonFormField<String>(
              key: ValueKey<String>(
                '$title-$index-${selectedId ?? 'none'}-${blockedIds.join('|')}',
              ),
              initialValue: selectedId,
              decoration: InputDecoration(labelText: 'Giocatore ${index + 1}'),
              items: players
                  .where(
                    (player) =>
                        !blockedIds.contains(player.id) ||
                        player.id == selectedId,
                  )
                  .map(
                    (player) => DropdownMenuItem<String>(
                      value: player.id,
                      child: Text(player.name),
                    ),
                  )
                  .toList(),
              onChanged: (playerId) {
                final updated = List<String>.from(selectedIds);
                while (updated.length <= index) {
                  updated.add('');
                }
                updated[index] = playerId ?? '';
                onChanged(_normalizedTeam(updated));
              },
            ),
          );
        }),
      ],
    );
  }
}

class _ScorersEditor extends StatelessWidget {
  const _ScorersEditor({
    required this.title,
    required this.teamIds,
    required this.players,
    required this.scorerIds,
    required this.onChanged,
  });

  final String title;
  final List<String> teamIds;
  final List<Player> players;
  final List<String?> scorerIds;
  final void Function(int index, String playerId) onChanged;

  @override
  Widget build(BuildContext context) {
    if (scorerIds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterSectionLabel(title),
        const SizedBox(height: 6),
        ...scorerIds.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButtonFormField<String>(
              key: ValueKey<String>(
                '$title-${entry.key}-${entry.value ?? 'none'}-${teamIds.join('|')}',
              ),
              initialValue: teamIds.contains(entry.value) ? entry.value : null,
              decoration: InputDecoration(labelText: 'Gol ${entry.key + 1}'),
              items: teamIds
                  .map(
                    (playerId) => DropdownMenuItem<String>(
                      value: playerId,
                      child: Text(StatsService.playerName(players, playerId)),
                    ),
                  )
                  .toList(),
              onChanged: (playerId) {
                if (playerId != null) {
                  onChanged(entry.key, playerId);
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

List<String?> _scorersForTeam(GameMatch match, List<String> teamIds) {
  final teamSet = teamIds.toSet();
  return match.scorerIds
      .where(teamSet.contains)
      .map<String?>((playerId) => playerId)
      .toList();
}

List<String> _normalizedTeam(List<String> ids) {
  return ids.where((id) => id.trim().isNotEmpty).toList();
}

int _currentScore(TextEditingController controller) {
  final score = int.tryParse(controller.text.trim());
  if (score == null || score < 0) {
    return 0;
  }
  return score;
}

void _fitTeamScorers(
  List<String?> scorerIds,
  List<String> teamIds,
  int targetGoals,
) {
  if (targetGoals < scorerIds.length) {
    scorerIds.removeRange(targetGoals, scorerIds.length);
  }
  while (scorerIds.length < targetGoals) {
    scorerIds.add(null);
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
    final summaryLabel = hasActiveFilters ? label : 'Tutti i risultati';
    return Material(
      color: NttColors.surfaceMid,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenFilters,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return Container(
              padding: EdgeInsets.fromLTRB(16, 14, compact ? 6 : 10, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasActiveFilters
                      ? NttColors.accent.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.filter_alt_outlined,
                      size: 22,
                      color: hasActiveFilters
                          ? NttColors.accent
                          : NttColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              hasActiveFilters ? 'Filtri attivi' : 'Filtri',
                              style: const TextStyle(
                                color: NttColors.textFaint,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            if (!compact) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: hasActiveFilters
                                      ? NttColors.accent.withValues(alpha: 0.14)
                                      : NttColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$matchesCount partite',
                                  style: TextStyle(
                                    color: hasActiveFilters
                                        ? NttColors.accentSoft
                                        : NttColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summaryLabel,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: NttColors.textPrimary,
                            fontSize: compact ? 16 : 18,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasActiveFilters)
                        compact
                            ? IconButton(
                                key: const ValueKey('history-reset-filters'),
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Reset filtri',
                                icon: const Icon(Icons.refresh, size: 18),
                                color: NttColors.accent,
                                onPressed: onReset,
                              )
                            : TextButton(
                                key: const ValueKey('history-reset-filters'),
                                onPressed: onReset,
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Reset'),
                              )
                      else
                        SizedBox(height: compact ? 28 : 32),
                      IconButton(
                        key: const ValueKey('history-open-filters'),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Apri filtri',
                        icon: const Icon(Icons.chevron_right, size: 22),
                        color: NttColors.accent,
                        onPressed: onOpenFilters,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NttColors.accent,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      child: const Text('Annulla'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      key: const ValueKey('history-apply-filters'),
                      onPressed: () => Navigator.of(context).pop(_draftFilters),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      child: const Text('Applica'),
                    ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ...players.map((player) {
              final selected = selectedPlayerId == player.id;
              return ChoiceChip(
                key: ValueKey('history-player-${player.id}'),
                label: Text(player.name),
                selected: selected,
                onSelected: (_) => onSelected(player.id),
                labelStyle: TextStyle(
                  color: selected
                      ? NttColors.surfaceDark
                      : NttColors.textPrimary,
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
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final MatchDayGroup group;
  final List<Player> players;
  final Animation<double> anim;
  final double delay;
  final ValueChanged<GameMatch> onOpen;
  final ValueChanged<GameMatch> onEdit;
  final ValueChanged<GameMatch> onDelete;

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
              (match) => _MatchCard(
                match: match,
                players: players,
                onOpen: () => onOpen(match),
                onEdit: () => onEdit(match),
                onDelete: () => onDelete(match),
              ),
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
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final GameMatch match;
  final List<Player> players;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('HH:mm').format(match.playedAt);
    final baseModeLabel = match.mode == MatchMode.oneVsOne ? '1v1' : '2v2';
    final modeLabel =
        match.isRivalry ? 'Rivalita · $baseModeLabel' : baseModeLabel;
    final t1Names =
        match.team1.map((id) => StatsService.playerName(players, id)).toList();
    final t2Names =
        match.team2.map((id) => StatsService.playerName(players, id)).toList();
    final winColor = match.winningTeam == 1 ? NttColors.team1 : NttColors.team2;
    final modeColor = match.isRivalry
        ? NttColors.team2
        : (match.mode == MatchMode.oneVsOne
            ? NttColors.warning
            : NttColors.accentSoft);

    return Card(
      key: ValueKey('history-match-${match.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: winColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<_MatchAction>(
                        tooltip: 'Azioni partita',
                        onSelected: (action) {
                          switch (action) {
                            case _MatchAction.edit:
                              onEdit();
                            case _MatchAction.delete:
                              onDelete();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<_MatchAction>(
                            value: _MatchAction.edit,
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Correggi'),
                            ),
                          ),
                          PopupMenuItem<_MatchAction>(
                            value: _MatchAction.delete,
                            child: ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text('Elimina'),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: NttColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          modeLabel,
                          style: TextStyle(
                            color: modeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
      ),
    );
  }
}

enum _MatchAction { edit, delete }

class _MatchDetailsSheet extends StatelessWidget {
  const _MatchDetailsSheet({required this.match, required this.players});

  final GameMatch match;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(match.playedAt);
    final time = DateFormat('HH:mm').format(match.playedAt);
    final team1 = match.team1
        .map((id) => StatsService.playerName(players, id))
        .join(' / ');
    final team2 = match.team2
        .map((id) => StatsService.playerName(players, id))
        .join(' / ');
    final mode = match.mode == MatchMode.oneVsOne ? '1v1' : '2v2';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NttColors.textFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Dettagli partita',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          _MatchDetailRow(label: 'Data e ora', value: '$date · $time'),
          _MatchDetailRow(
            label: 'Formato',
            value: match.isRivalry ? 'Rivalita · $mode' : mode,
          ),
          _MatchDetailRow(
            label: 'Squadra 1',
            value: '$team1  ${match.t1Score}',
          ),
          _MatchDetailRow(
            label: 'Squadra 2',
            value: '$team2  ${match.t2Score}',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('match-details-delete'),
                  onPressed: () =>
                      Navigator.of(context).pop(_MatchAction.delete),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Elimina'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  key: const ValueKey('match-details-edit'),
                  onPressed: () => Navigator.of(context).pop(_MatchAction.edit),
                  icon: const Icon(Icons.edit),
                  label: const Text('Correggi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchDetailRow extends StatelessWidget {
  const _MatchDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: NttColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
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
    final namesLabel = names.join(' / ');
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
            namesLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWinner ? NttColors.textPrimary : NttColors.textMuted,
              fontSize: 16,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$score',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isWinner ? color : NttColors.textFaint,
              fontSize: 28,
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
