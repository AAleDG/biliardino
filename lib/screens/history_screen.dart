import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/design/brand_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubits/history/history_cubit.dart';
import '../cubits/history/history_filters.dart';
import '../cubits/history/history_logic.dart';
import '../cubits/history/history_state.dart';
import '../models/game_match.dart';
import '../models/player.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design/adaptive_pair.dart';

import 'history/history_artwork.dart';
import '../presentation/app_presentation.dart';

part 'history/history_filters_sheet.dart';
part 'history/history_details.dart';
part 'history/history_match_card.dart';
part 'history/history_filter_summary.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<HistoryCubit, HistoryState>(
    builder: (context, state) {
      final media = MediaQuery.of(context);
      final compact =
          media.size.height < 650 || media.textScaler.scale(1) > 1.3;
      final matches = state.filteredMatches;
      final daysByFirstMatch = {
        for (final group in state.groups) group.matches.first.id: group.day,
      };
      return Scaffold(
        appBar: brandAppBar(
          context,
          title: 'STORICO',
          compactTitle: true,
          showArtwork: false,
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: CustomScrollView(
            key: const ValueKey('history-scroll'),
            slivers: [
              if (!compact)
                const SliverToBoxAdapter(
                  child: HistoryRibbonArtwork(HistoryRibbon.header, height: 32),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.page,
                  AppSpace.page,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _FilterSummaryBar(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page,
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
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpace.section,
                                bottom: AppSpace.medium,
                              ),
                              child: Semantics(
                                header: true,
                                child: Text(
                                  dayLabel(day, DateTime.now()),
                                  style: AppType.utility.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: AppSpace.medium),
                          _MatchCard(
                            match: match,
                            players: state.players,
                            onOpen: () => _openMatchDetails(context, match),
                            onEdit: () => _openMatchEditor(context, match),
                            onDelete: () => _confirmDeleteMatch(context, match),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (matches.isNotEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: AppSpace.page,
                        bottom: media.padding.bottom,
                      ),
                      child: compact
                          ? const SizedBox(height: AppSpace.page)
                          : const HistoryRibbonArtwork(
                              HistoryRibbon.footer,
                              height: 100,
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
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
    backgroundColor: AppColors.surface,
    builder: (context) =>
        _MatchDetailsSheet(match: match, players: state.players),
  );
  if (action == null || !rootContext.mounted) {
    return;
  }
  switch (action) {
    case _MatchAction.edit:
      await _openMatchEditor(rootContext, match);
    case _MatchAction.delete:
      await _confirmDeleteMatch(rootContext, match);
  }
}

Future<void> _openMatchEditor(BuildContext rootContext, GameMatch match) async {
  final cubit = rootContext.read<HistoryCubit>();
  await Navigator.of(rootContext).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PresentationBuilder(
        builder: (presentation) => presentation.matchEditor(
          match: match,
          players: cubit.state.players,
          onSave: cubit.updateMatch,
        ),
      ),
    ),
  );
}

Future<void> _confirmDeleteMatch(
  BuildContext rootContext,
  GameMatch match,
) async {
  final confirmed = await showDialog<bool>(
    context: rootContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminare partita?'),
      content: const Text('La partita verrà rimossa dallo storico.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: AppTheme.primaryButton(
            background: AppColors.error,
            pressed: AppColors.error,
          ),
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

Future<void> _openFilters(BuildContext rootContext, HistoryState state) async {
  final cubit = rootContext.read<HistoryCubit>();
  final selectedFilters = await showModalBottomSheet<HistoryFilters>(
    context: rootContext,
    backgroundColor: AppColors.surface,
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

class _Empty extends StatelessWidget {
  const _Empty({required this.isFiltered});

  final bool isFiltered;

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
            const Icon(Icons.history, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
