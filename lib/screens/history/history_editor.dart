part of '../history_screen.dart';

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
              SwitchListTile.adaptive(
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
                      style: const TextStyle(color: AppColors.ink),
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
