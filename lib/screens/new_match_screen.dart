import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/celebrations.dart';

class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({super.key});

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final Map<String, int> _assignment = {};
  int _score1 = 0;
  int _score2 = 0;
  bool _kickedOff = false;

  List<String> _team(int t) => _assignment.entries
      .where((e) => e.value == t)
      .map((e) => e.key)
      .toList();

  void _setTeam(String id, int team) {
    setState(() {
      _assignment[id] = (_assignment[id] == team) ? 0 : team;
    });
  }

  void _addGoal(int team) {
    setState(() {
      if (team == 1) {
        _score1++;
      } else {
        _score2++;
      }
    });
    Celebrations.showGoal(
      context,
      color: team == 1 ? NttColors.team1 : NttColors.team2,
      teamLabel: 'SQUADRA $team',
    );
  }

  void _removeGoal(int team) {
    setState(() {
      if (team == 1 && _score1 > 0) {
        _score1--;
      } else if (team == 2 && _score2 > 0) {
        _score2--;
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _editScore(int team) async {
    final current = team == 1 ? _score1 : _score2;
    final controller = TextEditingController(text: '$current');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gol squadra $team'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Numero gol'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 0) Navigator.pop(ctx, v);
            },
            child: const Text('Imposta'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (team == 1) {
          _score1 = result;
        } else {
          _score2 = result;
        }
      });
    }
  }

  void _kickoff() {
    setState(() {
      _kickedOff = true;
      _score1 = 0;
      _score2 = 0;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _confirmExit() async {
    final ok = await _confirm(
      title: 'Abbandona la partita?',
      message: 'Tornerai alla composizione squadre e perderai il punteggio.',
      confirmLabel: 'Abbandona',
    );
    if (ok && mounted) {
      setState(() {
        _kickedOff = false;
        _score1 = 0;
        _score2 = 0;
      });
    }
  }

  Future<void> _confirmResetScore() async {
    final ok = await _confirm(
      title: 'Azzera il punteggio?',
      message: 'Le squadre restano invariate.',
      confirmLabel: 'Azzera',
    );
    if (ok && mounted) {
      setState(() {
        _score1 = 0;
        _score2 = 0;
      });
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _save(List<String> team1, List<String> team2) {
    if (_score1 == _score2) {
      _snack('Niente pareggi al biliardino: serve un vincitore.');
      return;
    }
    if (_score1 == 0 && _score2 == 0) {
      _snack('Inserisci almeno un gol prima di registrare.');
      return;
    }
    final state = context.read<AppState>();
    state.addMatch(
      team1: team1,
      team2: team2,
      score1: _score1,
      score2: _score2,
    );

    final s1Won = _score1 > _score2;
    final winningTeam = s1Won ? 1 : 2;
    final winningIds = s1Won ? team1 : team2;
    final winColor = s1Won ? NttColors.team1 : NttColors.team2;
    final winNames = winningIds.map(state.playerName).toList();
    final winScore = s1Won ? _score1 : _score2;
    final loseScore = s1Won ? _score2 : _score1;

    Celebrations.showVictory(
      context,
      color: winColor,
      teamLabel: 'SQUADRA $winningTeam',
      playerNames: winNames,
      winnerScore: winScore,
      loserScore: loseScore,
      onContinue: () {
        if (!mounted) return;
        setState(() {
          _assignment.clear();
          _score1 = 0;
          _score2 = 0;
          _kickedOff = false;
        });
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final present = state.players.where((p) => p.isPresent).toList();
    final team1 = _team(1);
    final team2 = _team(2);
    final teamsValid = team1.length == 2 && team2.length == 2;
    final showScoreboard = teamsValid && _kickedOff;

    return Scaffold(
      appBar: AppBar(
        title: Text(showScoreboard ? 'PARTITA IN CORSO' : 'NUOVA PARTITA'),
        leading: showScoreboard
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Torna alla composizione',
                onPressed: _confirmExit,
              )
            : null,
        actions: showScoreboard
            ? [
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Azzera punteggio',
                  onPressed: _confirmResetScore,
                ),
              ]
            : null,
      ),
      body: showScoreboard
          ? _Scoreboard(
              team1Names: team1.map(state.playerName).toList(),
              team2Names: team2.map(state.playerName).toList(),
              score1: _score1,
              score2: _score2,
              onAddGoal: _addGoal,
              onRemoveGoal: _removeGoal,
              onEditScore: _editScore,
              onSave: () => _save(team1, team2),
            )
          : _Setup(
              state: state,
              present: present,
              team1: team1,
              team2: team2,
              assignment: _assignment,
              onToggle: _setTeam,
              onKickoff: teamsValid ? _kickoff : null,
            ),
    );
  }
}

class _Setup extends StatelessWidget {
  const _Setup({
    required this.state,
    required this.present,
    required this.team1,
    required this.team2,
    required this.assignment,
    required this.onToggle,
    required this.onKickoff,
  });

  final AppState state;
  final List<Player> present;
  final List<String> team1;
  final List<String> team2;
  final Map<String, int> assignment;
  final void Function(String id, int team) onToggle;
  final VoidCallback? onKickoff;

  @override
  Widget build(BuildContext context) {
    if (present.length < 4) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.group_off, size: 64, color: NttColors.textFaint),
              SizedBox(height: 16),
              Text(
                'Servono almeno 4 giocatori presenti\nper una partita 2 vs 2.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NttColors.textMuted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Vai su Giocatori e segna chi è presente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: NttColors.textFaint, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              const _SectionLabel('COMPONI LE SQUADRE'),
              const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SetupTeamCard(
                        label: 'SQUADRA 1',
                        color: NttColors.team1,
                        names: team1.map(state.playerName).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SetupTeamCard(
                        label: 'SQUADRA 2',
                        color: NttColors.team2,
                        names: team2.map(state.playerName).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('GIOCATORI PRESENTI'),
              const SizedBox(height: 4),
              ...present.map((p) {
                final a = assignment[p.id] ?? 0;
                final t1Full = team1.length >= 2 && a != 1;
                final t2Full = team2.length >= 2 && a != 2;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        PlayerAvatar(name: p.name),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _TeamChip(
                          label: 'S1',
                          color: NttColors.team1,
                          selected: a == 1,
                          onTap: t1Full ? null : () => onToggle(p.id, 1),
                        ),
                        const SizedBox(width: 6),
                        _TeamChip(
                          label: 'S2',
                          color: NttColors.team2,
                          selected: a == 2,
                          onTap: t2Full ? null : () => onToggle(p.id, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onKickoff,
                icon: const Icon(Icons.sports_soccer),
                label: const Text('INIZIA PARTITA'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.team1Names,
    required this.team2Names,
    required this.score1,
    required this.score2,
    required this.onAddGoal,
    required this.onRemoveGoal,
    required this.onEditScore,
    required this.onSave,
  });

  final List<String> team1Names;
  final List<String> team2Names;
  final int score1;
  final int score2;
  final void Function(int team) onAddGoal;
  final void Function(int team) onRemoveGoal;
  final Future<void> Function(int team) onEditScore;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final canSave = score1 != score2 && (score1 > 0 || score2 > 0);
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: NttColors.surfaceMid,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _TeamPanel(
                        label: 'SQUADRA 1',
                        color: NttColors.team1,
                        playerNames: team1Names,
                        score: score1,
                        onAddGoal: () => onAddGoal(1),
                        onRemoveGoal: () => onRemoveGoal(1),
                        onLongPressScore: () => onEditScore(1),
                      ),
                    ),
                    Container(
                      width: 1.5,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    Expanded(
                      child: _TeamPanel(
                        label: 'SQUADRA 2',
                        color: NttColors.team2,
                        playerNames: team2Names,
                        score: score2,
                        onAddGoal: () => onAddGoal(2),
                        onRemoveGoal: () => onRemoveGoal(2),
                        onLongPressScore: () => onEditScore(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canSave ? onSave : null,
                icon: const Icon(Icons.flag),
                label: const Text('REGISTRA RISULTATO'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamPanel extends StatefulWidget {
  const _TeamPanel({
    required this.label,
    required this.color,
    required this.playerNames,
    required this.score,
    required this.onAddGoal,
    required this.onRemoveGoal,
    required this.onLongPressScore,
  });

  final String label;
  final Color color;
  final List<String> playerNames;
  final int score;
  final VoidCallback onAddGoal;
  final VoidCallback onRemoveGoal;
  final VoidCallback onLongPressScore;

  @override
  State<_TeamPanel> createState() => _TeamPanelState();
}

class _TeamPanelState extends State<_TeamPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant _TeamPanel old) {
    super.didUpdateWidget(old);
    if (widget.score > old.score) {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.color.withOpacity(0.20),
                widget.color.withOpacity(0.02),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _flash,
          builder: (_, __) {
            final t = 1 - _flash.value;
            final opacity = t * t * 0.55;
            return IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(opacity),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              ...widget.playerNames.map(
                (name) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NttColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onLongPress: widget.onLongPressScore,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.elasticOut,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, anim) {
                        return ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        );
                      },
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: FittedBox(
                        key: ValueKey(widget.score),
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${widget.score}',
                          style: TextStyle(
                            color: NttColors.textPrimary,
                            fontSize: 120,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -3,
                            shadows: [
                              Shadow(
                                color: widget.color.withOpacity(0.75),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: widget.onAddGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: NttColors.surfaceDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('+1 GOAL'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 32,
                child: TextButton.icon(
                  onPressed: widget.score > 0 ? widget.onRemoveGoal : null,
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('Annulla'),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.color,
                    disabledForegroundColor: NttColors.textFaint,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupTeamCard extends StatelessWidget {
  const _SetupTeamCard({
    required this.label,
    required this.color,
    required this.names,
  });

  final String label;
  final Color color;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final filled = names.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: NttColors.surfaceMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: filled == 2 ? color : Colors.white.withOpacity(0.08),
          width: filled == 2 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (names.isEmpty)
            const Text(
              '— vuota —',
              style: TextStyle(
                color: NttColors.textFaint,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            )
          else
            ...names.map(
              (n) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  n,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NttColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (names.length == 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '+ 1 da scegliere',
                style: TextStyle(
                  color: NttColors.textFaint,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? color.withOpacity(selected ? 1 : 0.55)
                : NttColors.textFaint.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? NttColors.surfaceDark
                : (enabled ? color : NttColors.textFaint),
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
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
        letterSpacing: 3,
      ),
    );
  }
}
