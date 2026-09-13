import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../cubits/match_editor/match_edit_draft.dart';
import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../theme/app_theme.dart';
import '../../widgets/design/adaptive_pair.dart';
import '../../widgets/design/brand_choice_selector.dart';
import '../../widgets/design/sheet_ribbon_accent.dart';
import 'distinta_team_card.dart';
import 'editor_choosers.dart';

class MatchEditorScreen extends StatefulWidget {
  const MatchEditorScreen({
    super.key,
    required this.match,
    required this.players,
    required this.onSave,
  });
  final GameMatch match;
  final List<Player> players;
  final Future<void> Function(GameMatch) onSave;
  @override
  State<MatchEditorScreen> createState() => _MatchEditorScreenState();
}

class _MatchEditorScreenState extends State<MatchEditorScreen> {
  late MatchEditDraft _draft = MatchEditDraft.fromMatch(widget.match);
  bool _saving = false, _allowPop = false, _confirming = false;
  String? _error;

  void _change(MatchEditDraft draft) {
    setState(() {
      _draft = draft;
      _error = null;
    });
  }

  Future<void> _pop() async {
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirm(String title, String message, String action) async {
    if (_confirming || _saving) return false;
    _confirming = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continua a modificare'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    _confirming = false;
    return result == true && mounted;
  }

  Future<void> _close() async {
    if (_saving || _confirming) return;
    if (!_draft.isDirty ||
        await _confirm(
          'Scartare le modifiche?',
          'La partita salvata resterà invariata.',
          'Scarta',
        )) {
      if (mounted) await _pop();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final error = _draft.validationError;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_draft.toMatch());
      if (mounted) await _pop();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Impossibile modificare la partita. Riprova.';
        });
      }
    }
  }

  Future<void> _mode(MatchMode mode) async {
    if (mode == _draft.mode) return;
    final next = _draft.withMode(mode);
    if (mode.teamSize < _draft.mode.teamSize) {
      if (!await _confirm(
        'Passare a 1 vs 1?',
        'Resterà il primo giocatore di ogni squadra. I gol degli altri giocatori dovranno essere riassegnati.',
        'Cambia formato',
      )) {
        return;
      }
    }
    if (mounted) _change(next);
  }

  Future<void> _player(int team, int slot) async {
    final occupied = {..._draft.team1, ..._draft.team2};
    final selected = await chooseReplacement(
      context,
      widget.players.where((p) => !occupied.contains(p.id)).toList(),
    );
    if (!mounted || selected == null) return;
    final ids = _draft.team(team);
    final old = slot < ids.length ? ids[slot] : '';
    if (_draft.goalsFor(old) > 0 &&
        !await _confirm(
          'Sostituire il giocatore?',
          'I suoi gol resteranno da assegnare. Nessun gol sarà attribuito automaticamente al sostituto.',
          'Sostituisci',
        )) {
      return;
    }
    if (mounted) _change(_draft.replacePlayer(team, slot, selected));
  }

  Future<void> _score(int team) async {
    final score = await chooseScore(context, team, _draft.score(team));
    if (mounted && score != null) _change(_draft.withScore(team, score));
  }

  Future<void> _date() async {
    final date = _draft.playedAt;
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(date.year < 1900 ? date.year : 1900),
      lastDate: DateTime(
        date.year > DateTime.now().year + 1
            ? date.year
            : DateTime.now().year + 1,
        12,
        31,
      ),
    );
    if (mounted && selected != null) _change(_draft.withDate(selected));
  }

  Future<void> _time() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draft.playedAt),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      helpText: 'Inserisci ora',
      hourLabelText: 'Ore',
      minuteLabelText: 'Minuti',
      cancelText: 'Annulla',
      confirmText: 'Conferma',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: Theme.of(context).timePickerTheme.copyWith(
            hourMinuteColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.background,
            ),
            hourMinuteTextColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.onPrimary
                  : AppColors.ink,
            ),
            hourMinuteTextStyle: AppType.bodyStrong.copyWith(fontSize: 32),
            timeSelectorSeparatorTextStyle: WidgetStatePropertyAll(
              AppType.bodyStrong.copyWith(fontSize: 32),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (mounted && selected != null) {
      _change(_draft.withTime(selected.hour, selected.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final constrained = scale > 1.3 || MediaQuery.sizeOf(context).height < 500;
    return PopScope(
      canPop: _allowPop || (!_draft.isDirty && !_saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : _close,
                      child: const Text('Annulla'),
                    ),
                    if (!constrained) const SizedBox(width: 8),
                    if (!constrained)
                      Expanded(
                        child: Text(
                          'CORREGGI PARTITA',
                          textAlign: TextAlign.right,
                          style: AppType.section.copyWith(
                            fontSize: scale > 1.3 ? 24 : 28,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (scale <= 1.3)
                const SizedBox(
                  height: 14,
                  width: double.infinity,
                  child: SheetRibbonAccent(),
                ),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _saving,
                  child: SingleChildScrollView(
                    key: const ValueKey('edit-match-scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(AppSpace.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (constrained) ...[
                          const Text(
                            'CORREGGI PARTITA',
                            style: AppType.section,
                          ),
                          const SizedBox(height: AppSpace.medium),
                        ],
                        AdaptivePair(
                          first: _MetadataButton(
                            label: DateFormat(
                              'dd/MM/yyyy',
                            ).format(_draft.playedAt),
                            semanticLabel: 'Modifica data',
                            icon: Icons.calendar_today,
                            onTap: _date,
                            key: const ValueKey('edit-date'),
                          ),
                          second: _MetadataButton(
                            label: DateFormat('HH:mm').format(_draft.playedAt),
                            semanticLabel: 'Modifica ora',
                            icon: Icons.schedule,
                            onTap: _time,
                            key: const ValueKey('edit-time'),
                          ),
                        ),
                        const SizedBox(height: AppSpace.medium),
                        BrandChoiceSelector<MatchMode>(
                          choices: const [
                            BrandChoice(
                              value: MatchMode.oneVsOne,
                              label: '1 VS 1',
                              semanticKey: ValueKey('edit-mode-1'),
                            ),
                            BrandChoice(
                              value: MatchMode.twoVsTwo,
                              label: '2 VS 2',
                              semanticKey: ValueKey('edit-mode-2'),
                            ),
                          ],
                          selected: _draft.mode,
                          onChanged: _mode,
                        ),
                        const SizedBox(height: AppSpace.medium),
                        for (final team in [1, 2]) ...[
                          DistintaTeamCard(
                            draft: _draft,
                            number: team,
                            players: widget.players,
                            onScore: (score) =>
                                _change(_draft.withScore(team, score)),
                            onEditScore: () => _score(team),
                            onPlayer: (slot) => _player(team, slot),
                            onGoals: (id, delta) =>
                                _change(_draft.changeGoals(team, id, delta)),
                            onConfirm: () =>
                                _change(_draft.confirmSingleScorer(team)),
                          ),
                          const SizedBox(height: AppSpace.medium),
                        ],
                        if (_draft.mode == MatchMode.oneVsOne ||
                            _draft.isRivalry)
                          SwitchListTile.adaptive(
                            key: const ValueKey('edit-rivalry'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            title: const Text('Rivalità'),
                            subtitle: _draft.mode == MatchMode.twoVsTwo
                                ? const Text('Già presente in questa partita')
                                : null,
                            value: _draft.isRivalry,
                            onChanged: (value) =>
                                _change(_draft.withRivalry(value)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Semantics(
                          key: const ValueKey('edit-match-error'),
                          container: true,
                          liveRegion: true,
                          label: _error,
                          child: ExcludeSemantics(
                            child: Text(
                              _error!,
                              style: AppType.utility.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ElevatedButton(
                      key: const ValueKey('edit-match-save'),
                      onPressed: _saving ? null : _save,
                      style: AppTheme.primaryButton(),
                      child: Text(
                        _saving
                            ? 'Salvataggio…'
                            : (constrained ? 'SALVA' : 'SALVA MODIFICHE'),
                        textAlign: TextAlign.center,
                        style: AppType.action,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataButton extends StatelessWidget {
  const _MetadataButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
  });
  final String label, semanticLabel;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$semanticLabel: $label',
    onTap: onTap,
    child: ExcludeSemantics(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: AppType.bodyStrong)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
