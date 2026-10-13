import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/history/history_cubit.dart';
import '../../../cubits/history/history_filters.dart';
import '../../../cubits/history/history_logic.dart';
import '../../../cubits/history/history_state.dart';
import '../../../models/game_match.dart';
import '../../../models/player.dart';
import '../../../repositories/match_repository.dart';
import '../../../repositories/player_repository.dart';
import '../../../services/stats_service.dart';
import '../theme/italia90_tokens.dart';
import '../widgets/italia90_components.dart';
import '../widgets/italia90_page.dart';
import '../../app_presentation.dart';
import 'history/history_details.dart';
import 'history/history_filter_summary.dart';
import 'history/history_filters_sheet.dart';
import 'history/history_match_card.dart';

/// Supplies a stable reference date to the history presentation when a
/// caller needs deterministic relative date labels, such as a visual fixture.
class HistoryClockScope extends InheritedWidget {
  const HistoryClockScope({super.key, required this.now, required super.child});

  final DateTime Function() now;

  static DateTime nowOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HistoryClockScope>()?.now() ??
      DateTime.now();

  @override
  bool updateShouldNotify(HistoryClockScope oldWidget) =>
      !identical(now, oldWidget.now);
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    if (_hasHistoryCubit(context)) {
      return _HistoryView(showBack: showBack);
    }
    return BlocProvider<HistoryCubit>(
      create: (ctx) => HistoryCubit(
        playerRepository: ctx.read<PlayerRepository>(),
        matchRepository: ctx.read<MatchRepository>(),
      ),
      child: _HistoryView(showBack: showBack),
    );
  }

  static bool _hasHistoryCubit(BuildContext context) {
    try {
      context.read<HistoryCubit>();
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final media = MediaQuery.of(context);
        final compact =
            media.size.height < 650 || media.textScaler.scale(1) > 1.3;
        final contentBottomPadding =
            media.padding.bottom + (compact ? Italia90.page : Italia90.xl);
        final now = HistoryClockScope.nowOf(context);
        final matches = state.filteredMatches;
        final daysByFirstMatch = {
          for (final group in state.groups) group.matches.first.id: group.day,
        };
        return ItaliaPage(
          title: 'STORICO',
          showBack: showBack,
          mastheadKey: const ValueKey('history-masthead'),
          footballKey: const ValueKey('history-brand-football'),
          child: CustomScrollView(
            key: const ValueKey('history-scroll'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Italia90.page,
                  Italia90.page,
                  Italia90.page,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: HistoryFilterSummaryBar(
                    matchesCount: state.matchesCount,
                    label: state.filterLabel,
                    hasActiveFilters: state.hasActiveFilters,
                    onOpenFilters: () => _openFilters(context, state),
                    onReset: context.read<HistoryCubit>().resetFilters,
                  ),
                ),
              ),
              if (matches.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Empty(isFiltered: state.hasActiveFilters),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    Italia90.page,
                    Italia90.sm,
                    Italia90.page,
                    contentBottomPadding,
                  ),
                  sliver: SliverList.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      final day = daysByFirstMatch[match.id];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (day != null)
                            _HistoryDayBand(label: dayLabel(day, now))
                          else
                            const SizedBox(height: Italia90.sm),
                          const SizedBox(height: Italia90.sm),
                          HistoryMatchCard(
                            match: match,
                            players: state.players,
                            onOpen: () => _openMatchDetails(context, match),
                            onEdit: () => _openEditMatchDialog(context, match),
                            onDelete: () => _confirmDeleteMatch(context, match),
                          ),
                          const SizedBox(height: Italia90.sm),
                        ],
                      );
                    },
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
  final action = await showModalBottomSheet<HistoryMatchAction>(
    context: rootContext,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Italia90.surface,
    builder: (context) =>
        HistoryMatchDetailsSheet(match: match, players: state.players),
  );
  if (action == null || !rootContext.mounted) {
    return;
  }
  switch (action) {
    case HistoryMatchAction.edit:
      await _openEditMatchDialog(rootContext, match);
    case HistoryMatchAction.delete:
      await _confirmDeleteMatch(rootContext, match);
  }
}

Future<void> _openEditMatchDialog(
  BuildContext rootContext,
  GameMatch match,
) async {
  final cubit = rootContext.read<HistoryCubit>();
  final state = cubit.state;
  final expectedGoals = match.t1Score + match.t2Score;
  if (match.mode == MatchMode.oneVsOne &&
      match.scorerIds.length == expectedGoals) {
    await Navigator.of(rootContext).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PresentationBuilder(
          builder: (presentation) => presentation.matchEditor(
            match: match,
            players: state.players,
            onSave: cubit.updateMatch,
          ),
        ),
      ),
    );
    return;
  }
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
                Semantics(
                  key: const ValueKey('edit-match-error'),
                  container: true,
                  liveRegion: true,
                  label: _error!,
                  child: ExcludeSemantics(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Italia90.error),
                    ),
                  ),
                ),
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
    backgroundColor: Italia90.surface,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => HistoryFiltersSheet(
      players: state.players,
      initialFilters: state.filters,
    ),
  );
  if (selectedFilters == null) {
    return;
  }
  cubit.applyFilters(selectedFilters);
}

// Kept for compatibility with the legacy editor's source layout.
// ignore: unused_element
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
    final countPill = DecoratedBox(
      decoration: BoxDecoration(
        color: hasActiveFilters ? Italia90.brickContainer : Italia90.subtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$matchesCount partite',
          style: Italia90.caption.copyWith(
            color: hasActiveFilters ? Italia90.primary : Italia90.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
    return Material(
      color: Italia90.panel,
      borderRadius: BorderRadius.circular(Italia90.panelRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Italia90.panelRadius),
        onTap: onOpenFilters,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
            final compact = constraints.maxWidth < 350 || largeText;
            return Container(
              constraints: BoxConstraints(
                minHeight: compact
                    ? largeText
                          ? 128
                          : 88
                    : 72,
              ),
              padding: EdgeInsets.fromLTRB(14, 8, compact ? 6 : 8, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Italia90.panelRadius),
                border: Border.all(
                  color: hasActiveFilters
                      ? Italia90.primary.withValues(alpha: 0.55)
                      : Italia90.outline.withValues(alpha: 0.65),
                ),
              ),
              child: compact
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.filter_alt_outlined,
                              size: 22,
                              color: hasActiveFilters
                                  ? Italia90.primary
                                  : Italia90.muted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                hasActiveFilters ? 'Filtri attivi' : 'Filtri',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Italia90.label.copyWith(fontSize: 15),
                              ),
                            ),
                            _HistoryFilterIconButton(
                              buttonKey: const ValueKey('history-open-filters'),
                              tooltip: 'Apri filtri',
                              icon: Icons.chevron_right,
                              onPressed: onOpenFilters,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            countPill,
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                summaryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Italia90.title.copyWith(fontSize: 16),
                              ),
                            ),
                            if (hasActiveFilters)
                              _HistoryFilterIconButton(
                                buttonKey: const ValueKey(
                                  'history-reset-filters',
                                ),
                                tooltip: 'Reset filtri',
                                icon: Icons.refresh,
                                iconSize: 20,
                                onPressed: onReset,
                              ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 24,
                          color: hasActiveFilters
                              ? Italia90.primary
                              : Italia90.muted,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          hasActiveFilters ? 'Filtri attivi' : 'Filtri',
                          style: Italia90.label.copyWith(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        countPill,
                        const SizedBox(width: 12),
                        Container(
                          width: 1,
                          height: 28,
                          color: Italia90.outline.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            summaryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Italia90.title.copyWith(fontSize: 17),
                          ),
                        ),
                        if (hasActiveFilters)
                          _HistoryFilterIconButton(
                            buttonKey: const ValueKey('history-reset-filters'),
                            tooltip: 'Reset filtri',
                            icon: Icons.refresh,
                            iconSize: 20,
                            onPressed: onReset,
                          ),
                        _HistoryFilterIconButton(
                          buttonKey: const ValueKey('history-open-filters'),
                          tooltip: 'Apri filtri',
                          icon: Icons.chevron_right,
                          onPressed: onOpenFilters,
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

class _HistoryFilterIconButton extends StatelessWidget {
  const _HistoryFilterIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 24,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    key: buttonKey,
    tooltip: tooltip,
    icon: Icon(icon, size: iconSize),
    color: Italia90.primary,
    onPressed: onPressed,
  );
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
                      color: Italia90.ink,
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
                        foregroundColor: Italia90.primary,
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
    return Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          color: Italia90.muted,
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
          labelStyle: TextStyle(
            color: selected && enabled ? Colors.white : Italia90.ink,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          ),
          selectedColor: enabled ? Italia90.primary : Italia90.subtle,
          backgroundColor: Italia90.subtle,
          disabledColor: Italia90.subtle.withValues(alpha: 0.45),
          side: BorderSide(
            color: selected && enabled
                ? Italia90.primary
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
                color: selectedPlayerId == null ? Colors.white : Italia90.ink,
                fontSize: 13,
                fontWeight: selectedPlayerId == null
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
              selectedColor: Italia90.primary,
              backgroundColor: Italia90.subtle,
              side: BorderSide(
                color: selectedPlayerId == null
                    ? Italia90.primary
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
                  color: selected ? Colors.white : Italia90.ink,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                ),
                selectedColor: Italia90.primary,
                backgroundColor: Italia90.subtle,
                side: BorderSide(
                  color: selected
                      ? Italia90.primary
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

class _HistoryDayBand extends StatelessWidget {
  const _HistoryDayBand({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 350;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final compact = narrow || largeText;
    final minHeight = narrow && !largeText ? 48.0 : 56.0;
    final fontSize = narrow && !largeText ? 24.0 : 30.0;
    final verticalPadding = largeText
        ? 10.0
        : narrow
        ? 8.0
        : 12.0;
    final rightPadding = narrow ? 68.0 : 92.0;
    return Semantics(
      header: true,
      label: label,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: ClipRRect(
            key: ValueKey('history-day-$label'),
            borderRadius: BorderRadius.circular(Italia90.panelRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Italia90.primary),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      verticalPadding,
                      rightPadding,
                      verticalPadding,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        softWrap: true,
                        style: Italia90.heading.copyWith(
                          color: Colors.white,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -minHeight * 0.35,
                    right: 12,
                    bottom: -minHeight * 0.35,
                    width: compact ? 60 : 76,
                    child: ItaliaDiagonalStripes(
                      backgroundColor: null,
                      stripeColor: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The grouped list now uses HistoryMatchCard; this remains for legacy callers.
// ignore: unused_element
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
    final modeLabel = match.isRivalry
        ? 'Rivalita · $baseModeLabel'
        : baseModeLabel;
    final t1Names = match.team1
        .map((id) => StatsService.playerName(players, id))
        .toList();
    final t2Names = match.team2
        .map((id) => StatsService.playerName(players, id))
        .toList();
    final winColor = match.winningTeam == 1
        ? Italia90.teamOne
        : Italia90.teamTwo;
    final modeColor = match.isRivalry ? Italia90.primary : Italia90.ink;

    return Card(
      key: ValueKey('history-match-${match.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Italia90.panelRadius),
        side: BorderSide(color: Italia90.outline.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onOpen,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: winColor, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MatchMetaRow(
                        timeLabel: timeLabel,
                        modeLabel: modeLabel,
                        modeColor: modeColor,
                        isRivalry: match.isRivalry,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                      const SizedBox(height: 8),
                      _TeamResultLine(
                        semanticKey: ValueKey(
                          'history-team-${match.id}-team-1',
                        ),
                        team: ItaliaTeam.one,
                        names: t1Names,
                        score: match.t1Score,
                        isWinner: match.winningTeam == 1,
                        showScore: false,
                      ),
                      const SizedBox(height: 4),
                      _TeamResultLine(
                        semanticKey: ValueKey(
                          'history-team-${match.id}-team-2',
                        ),
                        team: ItaliaTeam.two,
                        names: t2Names,
                        score: match.t2Score,
                        isWinner: match.winningTeam == 2,
                        showScore: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _MatchScoreRail(
                  matchId: match.id,
                  score1: match.t1Score,
                  score2: match.t2Score,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchMetaRow extends StatelessWidget {
  const _MatchMetaRow({
    required this.timeLabel,
    required this.modeLabel,
    required this.modeColor,
    required this.isRivalry,
    required this.onEdit,
    required this.onDelete,
  });

  final String timeLabel;
  final String modeLabel;
  final Color modeColor;
  final bool isRivalry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
      final stacked = largeText || constraints.maxWidth < 260;
      final menu = PopupMenuButton<_MatchAction>(
        tooltip: 'Azioni partita',
        padding: EdgeInsets.zero,
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
            child: ListTile(leading: Icon(Icons.edit), title: Text('Correggi')),
          ),
          PopupMenuItem<_MatchAction>(
            value: _MatchAction.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Elimina'),
            ),
          ),
        ],
      );

      final time = Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: Italia90.muted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              timeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Italia90.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      );

      final mode = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isRivalry ? Italia90.brickContainer : Italia90.subtle,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          modeLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: modeColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );

      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: time),
                menu,
              ],
            ),
            const SizedBox(height: 4),
            mode,
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: time),
          const SizedBox(width: 8),
          Flexible(child: mode),
          menu,
        ],
      );
    },
  );
}

class _MatchScoreRail extends StatelessWidget {
  const _MatchScoreRail({
    required this.matchId,
    required this.score1,
    required this.score2,
  });

  final String matchId;
  final int score1;
  final int score2;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Punteggio: Squadra 1 $score1, Squadra 2 $score2',
    child: ExcludeSemantics(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScoreCell(
            key: ValueKey('history-score-$matchId-team-1'),
            value: score1,
            background: Italia90.blueContainer,
            foreground: Italia90.teamOne,
          ),
          const SizedBox(height: 4),
          _ScoreCell(
            key: ValueKey('history-score-$matchId-team-2'),
            value: score2,
            background: Italia90.teamTwoContainer,
            foreground: Italia90.ink,
          ),
        ],
      ),
    ),
  );
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    super.key,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final int value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: SizedBox(
      width: 44,
      height: 42,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$value',
          style: Italia90.heading.copyWith(color: foreground, fontSize: 30),
        ),
      ),
    ),
  );
}

enum _MatchAction { edit, delete }

// The details sheet now lives in the history feature module.
// ignore: unused_element
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Italia90.muted,
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
                    onPressed: () =>
                        Navigator.of(context).pop(_MatchAction.edit),
                    icon: const Icon(Icons.edit),
                    label: const Text('Correggi'),
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
            child: Text(label, style: const TextStyle(color: Italia90.muted)),
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
    required this.semanticKey,
    required this.team,
    required this.names,
    required this.score,
    required this.isWinner,
    this.showScore = true,
  });

  final Key semanticKey;
  final ItaliaTeam team;
  final List<String> names;
  final int score;
  final bool isWinner;
  final bool showScore;

  @override
  Widget build(BuildContext context) {
    final namesLabel = names.join(' / ');
    return Semantics(
      key: semanticKey,
      container: true,
      label:
          '${team.label}: $namesLabel, punteggio $score'
          '${isWinner ? ', vittoria' : ''}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: team.color.withValues(alpha: isWinner ? 1 : 0.35),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                namesLabel,
                style: TextStyle(
                  color: isWinner ? Italia90.ink : Italia90.muted,
                  fontSize: 16,
                  fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            if (showScore) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$score',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: isWinner ? team.onNeutralSurface : Italia90.muted,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.isFiltered});
  final bool isFiltered;

  @override
  Widget build(BuildContext context) => ItaliaEmptyState(
    icon: Icons.history,
    title: isFiltered ? 'Nessuna partita trovata' : 'Nessuna partita',
    description: isFiltered
        ? 'Cambia filtro per consultare altri risultati.'
        : 'Registra una partita per popolare lo storico.',
  );
}
