import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/design/brand_header.dart';
import '../widgets/design/score_panel.dart';
import '../widgets/design/match_setup_view.dart';
import '../widgets/design/match_options_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/home/home_cubit.dart';
import '../cubits/new_match/new_match_cubit.dart';
import '../cubits/new_match/new_match_state.dart';
import '../models/game_match.dart';
import '../models/match_rules.dart';
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

class _NewMatchView extends StatefulWidget {
  const _NewMatchView();

  @override
  State<_NewMatchView> createState() => _NewMatchViewState();
}

class _NewMatchViewState extends State<_NewMatchView> {
  CelebrationOverlayHandle? _victoryOverlay;
  CelebrationOverlayHandle? _goalOverlay;

  void _dismissGoalOverlay() {
    _goalOverlay?.dismiss();
    _goalOverlay = null;
  }

  @override
  void dispose() {
    _dismissGoalOverlay();
    _dismissVictoryOverlay();
    super.dispose();
  }

  void _dismissVictoryOverlay() {
    _victoryOverlay?.dismiss();
    _victoryOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NewMatchCubit, NewMatchState>(
          listenWhen: (previous, current) =>
              !current.kickedOff ||
              current.score1 < previous.score1 ||
              current.score2 < previous.score2,
          listener: (_, _) => _dismissGoalOverlay(),
        ),
        BlocListener<HomeCubit, HomeDestination>(
          listenWhen: (previous, current) => previous != current,
          listener: (ctx, state) {
            if (state == HomeDestination.match) {
              final pending = ctx.read<NewMatchCubit>().state.pendingVictory;
              if (pending != null) {
                _confirmCompletedMatch(ctx, pending);
              }
              return;
            }
            _dismissGoalOverlay();
            _dismissVictoryOverlay();
            final cubit = ctx.read<NewMatchCubit>();
            if (cubit.state.lastVictory != null) {
              cubit.acknowledgeVictory();
            }
          },
        ),
        BlocListener<NewMatchCubit, NewMatchState>(
          listenWhen: (p, n) => n.lastGoal != null && n.lastGoal != p.lastGoal,
          listener: (ctx, state) {
            final goal = state.lastGoal!;
            if (ctx.read<HomeCubit>().state != HomeDestination.match) {
              return;
            }
            if (state.pendingVictory != null) {
              HapticFeedback.mediumImpact();
              return;
            }
            _dismissGoalOverlay();
            _goalOverlay = Celebrations.showGoal(
              ctx,
              color: goal.team == 1 ? AppColors.teamOne : AppColors.teamTwo,
              teamLabel: state.isRivalry
                  ? 'RIVALITA · ${goal.scorerName.toUpperCase()}'
                  : '${goal.scorerName.toUpperCase()} · SQUADRA ${goal.team}',
            );
          },
        ),
        BlocListener<NewMatchCubit, NewMatchState>(
          listenWhen: (p, n) =>
              n.pendingVictory != null && n.pendingVictory != p.pendingVictory,
          listener: (ctx, state) {
            _dismissGoalOverlay();
            if (ctx.read<HomeCubit>().state == HomeDestination.match) {
              _confirmCompletedMatch(ctx, state.pendingVictory!);
            }
          },
        ),
        BlocListener<NewMatchCubit, NewMatchState>(
          listenWhen: (p, n) =>
              n.lastVictory != null && n.lastVictory != p.lastVictory,
          listener: (ctx, state) {
            if (ctx.read<HomeCubit>().state != HomeDestination.match) {
              ctx.read<NewMatchCubit>().acknowledgeVictory();
              return;
            }
            final victory = state.lastVictory!;
            final color = victory.winningTeam == 1
                ? AppColors.teamOne
                : AppColors.teamTwo;
            _dismissVictoryOverlay();
            _victoryOverlay = Celebrations.showVictory(
              ctx,
              color: color,
              teamLabel: state.isRivalry
                  ? 'RIVALITA · ${victory.winnerNames.join(' / ').toUpperCase()}'
                  : 'SQUADRA ${victory.winningTeam}',
              playerNames: victory.winnerNames,
              winnerScore: victory.winnerScore,
              loserScore: victory.loserScore,
              onChangeTeams: () {
                _victoryOverlay = null;
                ctx.read<NewMatchCubit>().changeTeamsAfterVictory();
              },
              onRematch: () {
                _victoryOverlay = null;
                ctx.read<NewMatchCubit>().rematchAfterVictory();
              },
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
            appBar: showScoreboard
                ? brandAppBar(
                    context,
                    compactTitle: true,
                    title: 'PARTITA IN CORSO',
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Torna alla composizione',
                      onPressed: state.isSaving
                          ? null
                          : () => _confirmExit(context, cubit),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.restart_alt),
                        tooltip: 'Azzera punteggio',
                        onPressed: state.isSaving
                            ? null
                            : () => _confirmResetScore(context, cubit),
                      ),
                    ],
                  )
                : null,
            body: showScoreboard
                ? _Scoreboard(
                    rules: state.rules,
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
                    awaitingConfirmation: state.pendingVictory != null,
                    onAddGoal: (team, players) =>
                        _handleAddGoal(context, team, players),
                    onRemoveGoal: cubit.removeGoal,
                    onSave: cubit.save,
                  )
                : MatchSetupView(
                    players: state.players,
                    mode: state.mode,
                    rules: state.rules,
                    isPersistingRules: state.isPersistingRules,
                    isRivalry: state.isRivalry,
                    present: state.present,
                    team1: state.team1,
                    team2: state.team2,
                    assignment: state.assignment,
                    onModeChanged: cubit.setMatchMode,
                    onOptionsPressed: () => showMatchOptions(context),
                    onToggle: cubit.setTeam,
                    onReplace: cubit.replaceTeamPlayer,
                    onKickoff: state.teamsValid && !state.isPersistingRules
                        ? cubit.kickoff
                        : null,
                  ),
          );
        },
      ),
    );
  }
}

Future<void> _confirmCompletedMatch(
  BuildContext context,
  VictoryEvent victory,
) async {
  final cubit = context.read<NewMatchCubit>();
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Registrare la vittoria?'),
      content: Text(
        'Squadra ${victory.winningTeam} ha raggiunto la condizione di vittoria '
        '${victory.winnerScore}-${victory.loserScore}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Correggi'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Registra'),
        ),
      ],
    ),
  );
  if (!context.mounted) {
    return;
  }
  if (confirmed ?? false) {
    await cubit.confirmAndSaveCompletedMatch();
  } else {
    cubit.correctScoreBeforeConfirmation();
  }
}

List<_MatchPlayer> _matchPlayers(List<Player> players, List<String> ids) {
  return ids
      .map(
        (id) =>
            _MatchPlayer(id: id, name: StatsService.playerName(players, id)),
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
          isScrollControlled: true,
          useSafeArea: true,
          builder: (ctx) => SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi ha segnato per la squadra $team?',
                    style: AppType.player,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Assegna il gol al giocatore corretto.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
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

class _MatchPlayer {
  const _MatchPlayer({required this.id, required this.name});

  final String id;
  final String name;
}

Future<void> _confirmExit(BuildContext context, NewMatchCubit cubit) async {
  final ok = await _confirmDialog(
    context,
    title: 'Abbandona la partita?',
    message: 'Tornerai alla composizione squadre e perderai il punteggio.',
    confirmLabel: 'Abbandona',
    destructive: true,
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
    destructive: true,
  );
  if (ok) cubit.resetScore();
}

Future<bool> _confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
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
          style: destructive
              ? AppTheme.primaryButton(
                  background: AppColors.error,
                  pressed: AppColors.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.rules,
    required this.isRivalry,
    required this.rivalry,
    required this.team1Players,
    required this.team2Players,
    required this.score1,
    required this.score2,
    required this.isSaving,
    required this.awaitingConfirmation,
    required this.onAddGoal,
    required this.onRemoveGoal,
    required this.onSave,
  });

  final MatchRules rules;
  final bool isRivalry;
  final RivalryOverview? rivalry;
  final List<_MatchPlayer> team1Players;
  final List<_MatchPlayer> team2Players;
  final int score1;
  final int score2;
  final bool isSaving;
  final bool awaitingConfirmation;
  final Future<void> Function(int team, List<_MatchPlayer> players) onAddGoal;
  final void Function(int team) onRemoveGoal;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final canSave =
        !isSaving &&
        !awaitingConfirmation &&
        rules.isFree &&
        score1 != score2 &&
        (score1 > 0 || score2 > 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 360;
        final panels = Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ScorePanel(
                  teamNumber: 1,
                  label: 'SQUADRA 1',
                  color: AppColors.teamOne,
                  playerNames: team1Players
                      .map((player) => player.name)
                      .toList(),
                  score: score1,
                  enabled: !isSaving && !awaitingConfirmation,
                  onAddGoal: () => onAddGoal(1, team1Players),
                  onRemoveGoal: () => onRemoveGoal(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ScorePanel(
                  teamNumber: 2,
                  label: 'SQUADRA 2',
                  color: AppColors.teamTwo,
                  playerNames: team2Players
                      .map((player) => player.name)
                      .toList(),
                  score: score2,
                  enabled: !isSaving && !awaitingConfirmation,
                  onAddGoal: () => onAddGoal(2, team2Players),
                  onRemoveGoal: () => onRemoveGoal(2),
                ),
              ),
            ],
          ),
        );
        final content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _RulesScoreboardBanner(rules: rules),
            ),
            if (isRivalry &&
                rivalry != null &&
                team1Players.isNotEmpty &&
                team2Players.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _RivalryScoreboardBanner(
                  overview: rivalry!,
                  team1Name: team1Players
                      .map((player) => player.name)
                      .join(' / '),
                  team2Name: team2Players
                      .map((player) => player.name)
                      .join(' / '),
                ),
              ),
            if (compact)
              SizedBox(height: 360, child: panels)
            else
              Expanded(child: panels),
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
                      textStyle: AppType.action,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
        return compact ? SingleChildScrollView(child: content) : content;
      },
    );
  }
}

class _RulesScoreboardBanner extends StatelessWidget {
  const _RulesScoreboardBanner({required this.rules});

  final MatchRules rules;

  @override
  Widget build(BuildContext context) {
    final text = rules.mode == MatchRuleMode.free
        ? 'PUNTEGGIO LIBERO'
        : rules.winByTwo
        ? 'PRIMO A ${rules.targetScore} · +2'
        : 'PRIMO A ${rules.targetScore}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.6,
        ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RIVALITA ATTIVA',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _rivalryHeadline(overview, team1Name, team2Name),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
  final leaderName = overview.team1Wins > overview.team2Wins
      ? team1Name
      : team2Name;
  return '$leaderName conduce ${overview.team1Wins}-${overview.team2Wins}, con ${overview.team1Goals}-${overview.team2Goals} nei gol assegnati.';
}
