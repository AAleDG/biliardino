import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/new_match/new_match_cubit.dart';
import '../cubits/new_match/new_match_state.dart';
import '../models/game_match.dart';
import '../models/player.dart';
import '../models/rivalry_overview.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/celebrations.dart';

class NewMatchScreen extends StatelessWidget {
  const NewMatchScreen({super.key});

  @override
  Widget build(BuildContext context) => const _NewMatchView();
}

class _NewMatchView extends StatelessWidget {
  const _NewMatchView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NewMatchCubit, NewMatchState>(
          listenWhen: (p, n) => n.lastGoal != null && n.lastGoal != p.lastGoal,
          listener: (ctx, state) {
            final goal = state.lastGoal!;
            Celebrations.showGoal(
              ctx,
              color: goal.team == 1 ? NttColors.team1 : NttColors.team2,
              teamLabel: state.isRivalry
                  ? 'RIVALITA · ${goal.scorerName.toUpperCase()}'
                  : '${goal.scorerName.toUpperCase()} · SQUADRA ${goal.team}',
            );
          },
        ),
        BlocListener<NewMatchCubit, NewMatchState>(
          listenWhen: (p, n) =>
              n.lastVictory != null && n.lastVictory != p.lastVictory,
          listener: (ctx, state) {
            final victory = state.lastVictory!;
            final color =
                victory.winningTeam == 1 ? NttColors.team1 : NttColors.team2;
            Celebrations.showVictory(
              ctx,
              color: color,
              teamLabel: state.isRivalry
                  ? 'RIVALITA · ${victory.winnerNames.join(' / ').toUpperCase()}'
                  : 'SQUADRA ${victory.winningTeam}',
              playerNames: victory.winnerNames,
              winnerScore: victory.winnerScore,
              loserScore: victory.loserScore,
              onChangeTeams: ctx.read<NewMatchCubit>().changeTeamsAfterVictory,
              onRematch: ctx.read<NewMatchCubit>().rematchAfterVictory,
            );
          },
        ),
        BlocListener<NewMatchCubit, NewMatchState>(
          listenWhen: (p, n) =>
              n.lastFeedback != null && n.lastFeedback != p.lastFeedback,
          listener: (ctx, state) {
            final message = _feedbackText(state.lastFeedback!.kind, state.mode);
            ScaffoldMessenger.of(ctx)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          },
        ),
      ],
      child: BlocBuilder<NewMatchCubit, NewMatchState>(
        builder: (context, state) {
          final cubit = context.read<NewMatchCubit>();
          final showScoreboard = state.showScoreboard;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                showScoreboard ? 'PARTITA IN CORSO' : 'NUOVA PARTITA',
              ),
              leading: showScoreboard
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Torna alla composizione',
                      onPressed: state.isSaving
                          ? null
                          : () => _confirmExit(context, cubit),
                    )
                  : null,
              actions: showScoreboard
                  ? [
                      IconButton(
                        icon: const Icon(Icons.restart_alt),
                        tooltip: 'Azzera punteggio',
                        onPressed: state.isSaving
                            ? null
                            : () => _confirmResetScore(context, cubit),
                      ),
                    ]
                  : null,
            ),
            body: showScoreboard
                ? _Scoreboard(
                    mode: state.mode,
                    isRivalry: state.isRivalry,
                    rivalry: state.isRivalry
                        ? StatsService.rivalryOverview(
                            state.matches,
                            team1Ids: state.team1,
                            team2Ids: state.team2,
                          )
                        : null,
                    team1Players: _matchPlayers(state.players, state.team1),
                    team2Players: _matchPlayers(state.players, state.team2),
                    score1: state.score1,
                    score2: state.score2,
                    isSaving: state.isSaving,
                    onAddGoal: (team, players) =>
                        _handleAddGoal(context, team, players),
                    onRemoveGoal: cubit.removeGoal,
                    onSave: cubit.save,
                  )
                : _Setup(
                    players: state.players,
                    matches: state.matches,
                    mode: state.mode,
                    isRivalry: state.isRivalry,
                    present: state.present,
                    team1: state.team1,
                    team2: state.team2,
                    assignment: state.assignment,
                    onModeChanged: cubit.setMatchMode,
                    onRivalryChanged: cubit.setRivalry,
                    onToggle: cubit.setTeam,
                    onKickoff: state.teamsValid ? cubit.kickoff : null,
                  ),
          );
        },
      ),
    );
  }
}

List<_MatchPlayer> _matchPlayers(List<Player> players, List<String> ids) {
  return ids
      .map(
        (id) => _MatchPlayer(
          id: id,
          name: StatsService.playerName(players, id),
        ),
      )
      .toList(growable: false);
}

String _feedbackText(NewMatchFeedback kind, MatchMode mode) {
  switch (kind) {
    case NewMatchFeedback.noWinner:
      return 'Niente pareggi al biliardino: serve un vincitore.';
    case NewMatchFeedback.noGoals:
      return 'Inserisci almeno un gol prima di registrare.';
    case NewMatchFeedback.invalidTeams:
      return mode.teamSize == 1
          ? 'Servono due squadre valide con un giocatore per lato.'
          : 'Servono due squadre valide con due giocatori per lato.';
    case NewMatchFeedback.saveFailed:
      return 'Impossibile salvare la partita. Riprova.';
    case NewMatchFeedback.playersUnavailable:
      return 'La partita è stata annullata: un giocatore non è più presente.';
  }
}

Future<void> _handleAddGoal(
  BuildContext context,
  int team,
  List<_MatchPlayer> players,
) async {
  final cubit = context.read<NewMatchCubit>();
  if (players.isEmpty) {
    return;
  }

  final scorer = players.length == 1
      ? players.first
      : await showModalBottomSheet<_MatchPlayer>(
          context: context,
          backgroundColor: NttColors.surfaceMid,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (ctx) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi ha segnato per la squadra $team?',
                    style: const TextStyle(
                      color: NttColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Assegna il gol al giocatore corretto.',
                    style: TextStyle(
                      color: NttColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...players.map(
                    (player) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: PlayerAvatar(name: player.name),
                        title: Text(player.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(ctx, player),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

  if (scorer != null) {
    cubit.addGoal(team, scorer.id);
  }
}

String _matchModeTitle(MatchMode mode) {
  switch (mode) {
    case MatchMode.oneVsOne:
      return '1 VS 1';
    case MatchMode.twoVsTwo:
      return '2 VS 2';
  }
}

String _playersNeededMessage(MatchMode mode) {
  final players = mode.teamSize * 2;
  return 'Servono almeno $players giocatori presenti\nper una partita ${_matchModeTitle(mode)}.';
}

String _slotHint(int capacity, int filled) {
  final remaining = capacity - filled;
  if (remaining <= 0) {
    return '';
  }
  return '+ $remaining da scegliere';
}

class _MatchPlayer {
  const _MatchPlayer({required this.id, required this.name});

  final String id;
  final String name;
}

class _ModeOption {
  const _ModeOption({
    required this.mode,
    required this.title,
    required this.description,
  });

  final MatchMode mode;
  final String title;
  final String description;
}

const _modeOptions = [
  _ModeOption(
    mode: MatchMode.oneVsOne,
    title: '1 VS 1',
    description: '2 giocatori totali, uno per squadra.',
  ),
  _ModeOption(
    mode: MatchMode.twoVsTwo,
    title: '2 VS 2',
    description: '4 giocatori totali, due per squadra.',
  ),
];

Future<void> _confirmExit(BuildContext context, NewMatchCubit cubit) async {
  final ok = await _confirmDialog(
    context,
    title: 'Abbandona la partita?',
    message: 'Tornerai alla composizione squadre e perderai il punteggio.',
    confirmLabel: 'Abbandona',
  );
  if (ok) cubit.abortMatch();
}

Future<void> _confirmResetScore(
  BuildContext context,
  NewMatchCubit cubit,
) async {
  final ok = await _confirmDialog(
    context,
    title: 'Azzera il punteggio?',
    message: 'Le squadre restano invariate.',
    confirmLabel: 'Azzera',
  );
  if (ok) cubit.resetScore();
}

Future<bool> _confirmDialog(
  BuildContext context, {
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

class _Setup extends StatelessWidget {
  const _Setup({
    required this.players,
    required this.matches,
    required this.mode,
    required this.isRivalry,
    required this.present,
    required this.team1,
    required this.team2,
    required this.assignment,
    required this.onModeChanged,
    required this.onRivalryChanged,
    required this.onToggle,
    required this.onKickoff,
  });

  final List<Player> players;
  final List<GameMatch> matches;
  final MatchMode mode;
  final bool isRivalry;
  final List<Player> present;
  final List<String> team1;
  final List<String> team2;
  final Map<String, int> assignment;
  final ValueChanged<MatchMode> onModeChanged;
  final ValueChanged<bool> onRivalryChanged;
  final void Function(String id, int team) onToggle;
  final VoidCallback? onKickoff;

  @override
  Widget build(BuildContext context) {
    final rivalry = isRivalry && team1.isNotEmpty && team2.isNotEmpty
        ? StatsService.rivalryOverview(
            matches,
            team1Ids: team1,
            team2Ids: team2,
          )
        : null;

    if (present.length < mode.teamSize * 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_off, size: 64, color: NttColors.textFaint),
              const SizedBox(height: 16),
              _MatchModeSelector(
                selectedMode: mode,
                onChanged: onModeChanged,
              ),
              const SizedBox(height: 20),
              Text(
                _playersNeededMessage(mode),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NttColors.textMuted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
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
              const _SectionLabel('MODALITA PARTITA'),
              const SizedBox(height: 8),
              _MatchModeSelector(
                selectedMode: mode,
                onChanged: onModeChanged,
              ),
              const SizedBox(height: 24),
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
                        capacity: mode.teamSize,
                        names: team1
                            .map((id) => StatsService.playerName(players, id))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SetupTeamCard(
                        label: 'SQUADRA 2',
                        color: NttColors.team2,
                        capacity: mode.teamSize,
                        names: team2
                            .map((id) => StatsService.playerName(players, id))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              if (team1.length == mode.teamSize &&
                  team2.length == mode.teamSize) ...[
                const SizedBox(height: 16),
                _RivalryToggleCard(
                  mode: mode,
                  isRivalry: isRivalry,
                  onActivate: () async {
                    final enabled = await _confirmRivalryActivation(
                      context,
                      mode: mode,
                    );
                    if (enabled) {
                      onRivalryChanged(true);
                    }
                  },
                  onDeactivate: () => onRivalryChanged(false),
                ),
              ],
              if (isRivalry) ...[
                const SizedBox(height: 12),
                _RivalryOverviewCard(
                  overview: rivalry,
                  team1Label: _teamLabel(players, team1, 'Squadra 1'),
                  team2Label: _teamLabel(players, team2, 'Squadra 2'),
                ),
              ],
              const SizedBox(height: 24),
              const _SectionLabel('GIOCATORI PRESENTI'),
              const SizedBox(height: 4),
              ...present.map((p) {
                final a = assignment[p.id] ?? 0;
                final t1Full = team1.length >= mode.teamSize && a != 1;
                final t2Full = team2.length >= mode.teamSize && a != 2;
                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    required this.mode,
    required this.isRivalry,
    required this.rivalry,
    required this.team1Players,
    required this.team2Players,
    required this.score1,
    required this.score2,
    required this.isSaving,
    required this.onAddGoal,
    required this.onRemoveGoal,
    required this.onSave,
  });

  final MatchMode mode;
  final bool isRivalry;
  final RivalryOverview? rivalry;
  final List<_MatchPlayer> team1Players;
  final List<_MatchPlayer> team2Players;
  final int score1;
  final int score2;
  final bool isSaving;
  final Future<void> Function(int team, List<_MatchPlayer> players) onAddGoal;
  final void Function(int team) onRemoveGoal;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final canSave = !isSaving && score1 != score2 && (score1 > 0 || score2 > 0);
    return Column(
      children: [
        if (isRivalry &&
            rivalry != null &&
            team1Players.isNotEmpty &&
            team2Players.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _RivalryScoreboardBanner(
              overview: rivalry!,
              team1Name: team1Players.map((player) => player.name).join(' / '),
              team2Name: team2Players.map((player) => player.name).join(' / '),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: NttColors.surfaceMid,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _TeamPanel(
                        label: 'SQUADRA 1',
                        color: NttColors.team1,
                        playerNames:
                            team1Players.map((player) => player.name).toList(),
                        score: score1,
                        enabled: !isSaving,
                        onAddGoal: () => onAddGoal(1, team1Players),
                        onRemoveGoal: () => onRemoveGoal(1),
                      ),
                    ),
                    Container(
                      width: 1.5,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    Expanded(
                      child: _TeamPanel(
                        label: 'SQUADRA 2',
                        color: NttColors.team2,
                        playerNames:
                            team2Players.map((player) => player.name).toList(),
                        score: score2,
                        enabled: !isSaving,
                        onAddGoal: () => onAddGoal(2, team2Players),
                        onRemoveGoal: () => onRemoveGoal(2),
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
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag),
                label: Text(
                  isSaving ? 'SALVATAGGIO...' : 'REGISTRA RISULTATO',
                ),
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
    required this.enabled,
    required this.onAddGoal,
    required this.onRemoveGoal,
  });

  final String label;
  final Color color;
  final List<String> playerNames;
  final int score;
  final bool enabled;
  final VoidCallback onAddGoal;
  final VoidCallback onRemoveGoal;

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
                widget.color.withValues(alpha: 0.20),
                widget.color.withValues(alpha: 0.02),
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
                  color: widget.color.withValues(alpha: opacity),
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
                              color: widget.color.withValues(alpha: 0.75),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: widget.enabled ? widget.onAddGoal : null,
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
                  onPressed: widget.enabled && widget.score > 0
                      ? widget.onRemoveGoal
                      : null,
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
    required this.capacity,
    required this.names,
  });

  final String label;
  final Color color;
  final int capacity;
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
          color:
              filled == capacity ? color : Colors.white.withValues(alpha: 0.08),
          width: filled == capacity ? 1.5 : 1,
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
                      color: color.withValues(alpha: 0.6),
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
          if (filled < capacity)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                _slotHint(capacity, filled),
                style: const TextStyle(
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

class _MatchModeSelector extends StatelessWidget {
  const _MatchModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  final MatchMode selectedMode;
  final ValueChanged<MatchMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final children = _modeOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final selected = option.mode == selectedMode;
          final card = InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(option.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? NttColors.accent.withValues(alpha: 0.12)
                    : NttColors.surfaceMid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? NttColors.accent
                      : Colors.white.withValues(alpha: 0.08),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      color:
                          selected ? NttColors.accent : NttColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.description,
                    style: const TextStyle(
                      color: NttColors.textMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (compact) {
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 8,
                right: index == _modeOptions.length - 1 ? 0 : 0,
              ),
              child: SizedBox(width: 172, child: card),
            );
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == _modeOptions.length - 1 ? 0 : 6,
              ),
              child: card,
            ),
          );
        }).toList(growable: false);

        if (compact) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(children: children),
          );
        }

        return Row(children: children);
      },
    );
  }
}

class _RivalryOverviewCard extends StatelessWidget {
  const _RivalryOverviewCard({
    required this.overview,
    required this.team1Label,
    required this.team2Label,
  });

  final RivalryOverview? overview;
  final String team1Label;
  final String team2Label;

  @override
  Widget build(BuildContext context) {
    final title = overview != null && overview!.hasMatches
        ? 'Testa a testa attivo'
        : 'Primo duello in arrivo';
    final description = overview != null && overview!.hasMatches
        ? _rivalryHeadline(overview!, team1Label, team2Label)
        : '$team1Label e $team2Label non si sono ancora affrontati in modalita Rivalita.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NttColors.surfaceMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NttColors.warning.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NttColors.warning.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: NttColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: NttColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: NttColors.textMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (overview != null && overview!.hasMatches) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _RivalryStatTile(
                    label: 'Duelli',
                    value: '${overview!.totalMatches}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RivalryStatTile(
                    label: 'Score',
                    value: '${overview!.team1Wins}-${overview!.team2Wins}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RivalryStatTile(
                    label: 'Gol',
                    value: '${overview!.team1Goals}-${overview!.team2Goals}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RivalryToggleCard extends StatelessWidget {
  const _RivalryToggleCard({
    required this.mode,
    required this.isRivalry,
    required this.onActivate,
    required this.onDeactivate,
  });

  final MatchMode mode;
  final bool isRivalry;
  final Future<void> Function() onActivate;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final description = mode == MatchMode.oneVsOne
        ? 'Puoi trasformare questa sfida in una Rivalita dedicata tra i due giocatori.'
        : 'Puoi trasformare questa partita in una Rivalita dedicata tra queste due coppie.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NttColors.surfaceMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NttColors.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_fire_department_outlined,
              color: NttColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRivalry
                      ? 'Rivalita attiva'
                      : 'Modalita Rivalita disponibile',
                  style: const TextStyle(
                    color: NttColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: NttColors.textMuted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isRivalry ? null : () => onActivate(),
                      icon: const Icon(Icons.flash_on_outlined),
                      label: const Text('Attiva Rivalita'),
                    ),
                    if (isRivalry)
                      TextButton(
                        onPressed: onDeactivate,
                        child: const Text('Disattiva'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RivalryScoreboardBanner extends StatelessWidget {
  const _RivalryScoreboardBanner({
    required this.overview,
    required this.team1Name,
    required this.team2Name,
  });

  final RivalryOverview overview;
  final String team1Name;
  final String team2Name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: NttColors.surfaceMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NttColors.warning.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RIVALITA ATTIVA',
            style: TextStyle(
              color: NttColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _rivalryHeadline(overview, team1Name, team2Name),
            style: const TextStyle(
              color: NttColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RivalryStatTile extends StatelessWidget {
  const _RivalryStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: NttColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: NttColors.textFaint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: NttColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _rivalryHeadline(
  RivalryOverview overview,
  String team1Name,
  String team2Name,
) {
  if (!overview.hasMatches) {
    return 'Nessun precedente tra $team1Name e $team2Name.';
  }
  if (overview.isTied) {
    return '$team1Name e $team2Name sono in parita: ${overview.team1Wins}-${overview.team2Wins} nei duelli diretti.';
  }
  final leaderName =
      overview.team1Wins > overview.team2Wins ? team1Name : team2Name;
  return '$leaderName conduce ${overview.team1Wins}-${overview.team2Wins}, con ${overview.team1Goals}-${overview.team2Goals} nei gol assegnati.';
}

String _teamLabel(List<Player> players, List<String> ids, String fallback) {
  if (ids.isEmpty) {
    return fallback;
  }
  return ids.map((id) => StatsService.playerName(players, id)).join(' / ');
}

Future<bool> _confirmRivalryActivation(
  BuildContext context, {
  required MatchMode mode,
}) {
  final subject = mode == MatchMode.oneVsOne
      ? 'tra questi due giocatori'
      : 'tra queste due coppie';
  return _confirmDialog(
    context,
    title: 'Attivare Rivalita?',
    message:
        'Puoi marcare questa partita come Rivalita $subject. Lo storico terra separati precedenti, score e gol dedicati a questa sfida.',
    confirmLabel: 'Attiva',
  );
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
                ? color.withValues(alpha: selected ? 1 : 0.55)
                : NttColors.textFaint.withValues(alpha: 0.3),
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
