import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/new_match/new_match_cubit.dart';
import '../../cubits/new_match/new_match_state.dart';
import '../../models/game_match.dart';
import '../../models/match_rules.dart';
import '../../theme/app_theme.dart';
import '../../widgets/design/adaptive_pair.dart';
import '../../widgets/design/sheet_ribbon_accent.dart';
import 'match_rivalry_summary.dart';

String _rulesSummary(MatchRules rules) => rules.isFree
    ? 'Punteggio libero'
    : 'Primo a ${rules.targetScore}${rules.winByTwo ? ' · Scarto di 2' : ''}';

class MatchOptionsSummary extends StatelessWidget {
  const MatchOptionsSummary({
    super.key,
    required this.rules,
    required this.isRivalry,
    required this.onPressed,
  });

  final MatchRules rules;
  final bool isRivalry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: AppColors.surface.withValues(alpha: .64),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('setup-options-action'),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OPZIONI PARTITA', style: AppType.action),
                    Text(
                      '${_rulesSummary(rules)}${isRivalry ? ' · Rivalità' : ''}',
                      style: AppType.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.tune, color: AppColors.primary, size: 20),
              if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
                const SizedBox(width: 6),
                Text(
                  'MODIFICA',
                  style: AppType.utility.copyWith(color: AppColors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showMatchOptions(BuildContext context) {
  final cubit = context.read<NewMatchCubit>();
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
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
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _MatchOptionsSheet()),
  );
}

class _MatchOptionsSheet extends StatelessWidget {
  const _MatchOptionsSheet();

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .72,
    minChildSize: .5,
    maxChildSize: .95,
    builder: (context, controller) => Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 64,
          child: SheetRibbonAccent(),
        ),
        SafeArea(
          top: false,
          child: Column(
            key: const ValueKey('match-options-sheet'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: const Text(
                              'OPZIONI PARTITA',
                              style: AppType.section,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('close-match-options'),
                          tooltip: 'Chiudi opzioni partita',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<NewMatchCubit, NewMatchState>(
                  builder: (context, state) {
                    final cubit = context.read<NewMatchCubit>();
                    final disabled = state.isPersistingRules;
                    final canGenerate =
                        !disabled &&
                        !state.kickedOff &&
                        !state.isSaving &&
                        state.present.length >= state.requiredPlayers;
                    final assignmentStyle = OutlinedButton.styleFrom(
                      textStyle: AppType.action,
                    );
                    return ListView(
                      key: const ValueKey('match-options-scroll'),
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        Text(
                          'Le modifiche si applicano subito.',
                          style: AppType.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _SectionTitle('Regole'),
                        const SizedBox(height: 10),
                        _RulesControls(state: state),
                        if (state.lastFeedback?.kind ==
                            NewMatchFeedback.saveFailed)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                'Impossibile salvare le opzioni. Riprova.',
                                style: AppType.body.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(height: 1),
                        ),
                        const _SectionTitle('Componi le squadre'),
                        const SizedBox(height: 12),
                        AdaptivePair(
                          first: OutlinedButton.icon(
                            key: const ValueKey('random-teams-action'),
                            style: assignmentStyle,
                            onPressed: !canGenerate
                                ? null
                                : () {
                                    cubit.generateRandomTeams();
                                    Navigator.pop(context);
                                  },
                            icon: const Icon(Icons.shuffle, size: 20),
                            label: const Text('CASUALI'),
                          ),
                          second: OutlinedButton.icon(
                            key: const ValueKey('balanced-teams-action'),
                            style: assignmentStyle,
                            onPressed: !canGenerate
                                ? null
                                : () {
                                    cubit.generateBalancedTeams();
                                    Navigator.pop(context);
                                  },
                            icon: const Icon(Icons.balance, size: 20),
                            label: const Text('BILANCIATE'),
                          ),
                        ),
                        if (state.teamsValid) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1),
                          ),
                          _OptionSwitch(
                            title: 'Modalità Rivalità',
                            value: state.isRivalry,
                            onChanged: disabled
                                ? null
                                : (enabled) async {
                                    if (!enabled ||
                                        await _confirmRivalry(
                                          context,
                                          state.mode,
                                        )) {
                                      if (context.mounted) {
                                        cubit.setRivalry(enabled);
                                      }
                                    }
                                  },
                          ),
                          if (state.rivalry case final overview?)
                            MatchRivalrySummary(
                              overview: overview,
                              players: state.players,
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RulesControls extends StatelessWidget {
  const _RulesControls({required this.state});
  final NewMatchState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewMatchCubit>();
    final rules = state.rules;
    final disabled = state.isPersistingRules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<MatchRuleMode>(
          key: const ValueKey('match-rule-selector'),
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: MatchRuleMode.free, label: Text('Libero')),
            ButtonSegment(
              value: MatchRuleMode.firstTo,
              label: Text('Primo a N'),
            ),
          ],
          selected: {rules.mode},
          onSelectionChanged: disabled
              ? null
              : (selection) => cubit.setRuleMode(selection.single),
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            textStyle: const WidgetStatePropertyAll(AppType.action),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.surface,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.onPrimary
                  : AppColors.ink,
            ),
            side: const WidgetStatePropertyAll(
              BorderSide(color: AppColors.divider),
            ),
          ),
        ),
        if (!rules.isFree) ...[
          const SizedBox(height: 16),
          AdaptivePair(
            first: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('Goal vittoria', style: AppType.body),
              ),
            ),
            second: Align(
              alignment: Alignment.centerRight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Diminuisci goal vittoria',
                      onPressed:
                          disabled ||
                              rules.targetScore <= MatchRules.minTargetScore
                          ? null
                          : () => cubit.setTargetScore(rules.targetScore - 1),
                      icon: const Icon(Icons.remove),
                      color: AppColors.primary,
                    ),
                    Semantics(
                      liveRegion: true,
                      label: 'Goal vittoria: ${rules.targetScore}',
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${rules.targetScore}',
                            style: AppType.section,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Aumenta goal vittoria',
                      onPressed:
                          disabled ||
                              rules.targetScore >= MatchRules.maxTargetScore
                          ? null
                          : () => cubit.setTargetScore(rules.targetScore + 1),
                      icon: const Icon(Icons.add),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _OptionSwitch(
            title: 'Scarto di 2 goal',
            value: rules.winByTwo,
            onChanged: disabled ? null : cubit.setWinByTwo,
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Text(title, style: AppType.bodyStrong));
}

class _OptionSwitch extends StatelessWidget {
  const _OptionSwitch({
    required this.title,
    required this.value,
    this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(title, style: AppType.bodyStrong),
    value: value,
    onChanged: onChanged,
  );
}

Future<bool> _confirmRivalry(BuildContext context, MatchMode mode) async {
  final subject = mode == MatchMode.oneVsOne
      ? 'tra questi due giocatori'
      : 'tra queste due coppie';
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Attivare Rivalità?'),
          content: Text(
            'Puoi marcare questa partita come Rivalità $subject. Lo storico '
            'terrà separati i precedenti dedicati a questa sfida.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Attiva'),
            ),
          ],
        ),
      ) ??
      false;
}
