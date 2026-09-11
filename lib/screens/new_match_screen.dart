import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/home/home_cubit.dart';
import '../cubits/new_match/new_match_cubit.dart';
import '../cubits/new_match/new_match_state.dart';
import '../models/game_match.dart';
import '../models/player.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/celebrations.dart';
import '../widgets/design/sheet_ribbon_accent.dart';
import 'new_match/live_match_view.dart';
import 'new_match/match_options_sheet.dart';
import 'new_match/match_setup_roster.dart';
import 'new_match/match_setup_view.dart';

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
            body: showScoreboard
                ? LiveMatchView(
                    rules: state.rules,
                    rivalry: state.isRivalry
                        ? StatsService.rivalryOverview(
                            state.matches,
                            team1Ids: state.team1,
                            team2Ids: state.team2,
                          )
                        : null,
                    team1Names: _matchPlayers(
                      state.players,
                      state.team1,
                    ).map((p) => p.name).toList(),
                    team2Names: _matchPlayers(
                      state.players,
                      state.team2,
                    ).map((p) => p.name).toList(),
                    score1: state.score1,
                    score2: state.score2,
                    isSaving: state.isSaving,
                    awaitingConfirmation: state.pendingVictory != null,
                    canRegisterResult: state.canRegisterResult,
                    onAddGoal: (team) => _handleAddGoal(
                      context,
                      team,
                      _matchPlayers(
                        state.players,
                        team == 1 ? state.team1 : state.team2,
                      ),
                    ),
                    onBack: () => _confirmExit(context, cubit),
                    onReset: () => _confirmResetScore(context, cubit),
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
                    onShowAllPlayers: () =>
                        showAllMatchPlayersSheet(context, cubit),
                    onAddPlayer: (team) =>
                        showMatchTeamPlayersSheet(context, cubit, team),
                    onEditPlayer: (team, playerId) => showMatchTeamPlayersSheet(
                      context,
                      cubit,
                      team,
                      replacingId: playerId,
                    ),
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
          backgroundColor: AppColors.background,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          sheetAnimationStyle: shouldReduceMotion(context)
              ? AnimationStyle.noAnimation
              : const AnimationStyle(
                  duration: AppMotion.navigation,
                  reverseDuration: AppMotion.navigation,
                ),
          builder: (ctx) => Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 64,
                child: SheetRibbonAccent(),
              ),
              SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ExcludeSemantics(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Chi ha segnato per la squadra $team?',
                              style: AppType.player,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Chiudi selezione marcatore',
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
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
                            leading: PlayerAvatar(
                              name: player.name,
                              color: team == 1
                                  ? AppColors.teamOne
                                  : AppColors.teamTwo,
                            ),
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
            ],
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
