import '../presentation/ranking_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/leaderboard/leaderboard_cubit.dart';
import '../cubits/leaderboard/leaderboard_state.dart';
import '../models/ranking_stats.dart';
import '../models/game_match.dart';
import '../navigation/app_navigation.dart';
import '../services/csv_share_service.dart';
import '../services/leaderboard_csv_service.dart';
import '../theme/app_theme.dart';
import 'leaderboard/ranking_row.dart';
import '../widgets/design/south_africa_artwork.dart';
import '../widgets/design/brand_header.dart';
import '../widgets/design/brand_choice_selector.dart';
import '../widgets/design/ranking_podium.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LeaderboardCubit, LeaderboardState>(
    builder: (context, state) {
      final pairs = state.selectedMode == MatchMode.twoVsTwo;
      final List<RankingStats> rankedByPoints = pairs
          ? state.teamGeneral
          : state.general;
      final List<RankingStats> rankedByGoals = pairs
          ? state.teamScorers
          : state.scorers;
      final compact =
          MediaQuery.sizeOf(context).height < 650 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final header = Column(
        children: [
          SizedBox(
            height: compact ? 12 : 36,
            width: double.infinity,
            child: const SouthAfricaArtwork(
              mark: ArtworkMark.headerRibbon,
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                if (!compact) const SizedBox(width: 48),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'CLASSIFICA',
                      textAlign: compact ? TextAlign.start : TextAlign.center,
                      style: compact ? AppType.section : AppType.screen,
                    ),
                  ),
                ),
                Builder(
                  builder: (buttonContext) => IconButton(
                    key: const ValueKey('leaderboard-export-csv'),
                    icon: const Icon(Icons.ios_share),
                    tooltip: 'Esporta CSV',
                    onPressed: rankedByPoints.isEmpty
                        ? null
                        : () => _shareLeaderboardCsv(
                            context: buttonContext,
                            csv: pairs
                                ? LeaderboardCsvService.buildPairs(
                                    state.teamGeneral,
                                  )
                                : LeaderboardCsvService.build(state.general),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<MatchMode>(
              key: const ValueKey('leaderboard-mode'),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(0, 48),
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: AppColors.onPrimary,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.ink,
                textStyle: AppType.action,
              ),
              segments: const [
                ButtonSegment(value: MatchMode.oneVsOne, label: Text('1vs1')),
                ButtonSegment(value: MatchMode.twoVsTwo, label: Text('2vs2')),
              ],
              selected: {state.selectedMode},
              onSelectionChanged: (modes) =>
                  context.read<LeaderboardCubit>().selectMode(modes.single),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => BrandChoiceSelector<int>(
                    selected: controller.index,
                    onChanged: controller.animateTo,
                    choices: const [
                      BrandChoice(value: 0, label: 'Generale'),
                      BrandChoice(value: 1, label: 'Marcatori'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
      final panes = TabBarView(
        children: [
          _LeaderboardPane(
            ranked: rankedByPoints,
            pairs: pairs,
            sectionLabel: 'CLASSIFICA COMPLETA',
            metricLabel: (stats) => '${stats.points} pt',
            rowDetail: (stats) =>
                '${stats.wins}V · ${stats.losses}P · ${stats.games} partite',
            emptyTitle: 'Nessuna partita giocata',
            emptyDescription: 'Registra una partita per vedere la classifica.',
          ),
          _LeaderboardPane(
            ranked: rankedByGoals,
            pairs: pairs,
            sectionLabel: 'CLASSIFICA MARCATORI',
            metricLabel: (stats) => '${stats.goalsScored} gol',
            rowDetail: (stats) =>
                '${stats.games} partite · ${stats.wins} vittorie',
            emptyTitle: 'Nessun marcatore disponibile',
            emptyDescription:
                'I gol compariranno qui dalle partite salvate con assegnazione marcatore.',
            emptyIcon: Icons.sports_soccer,
          ),
        ],
      );
      return RankingTabs(
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: MediaQuery.sizeOf(context).height < 450
                ? NestedScrollView(
                    headerSliverBuilder: (context, innerScrolled) => [
                      SliverToBoxAdapter(child: header),
                    ],
                    body: panes,
                  )
                : Column(
                    children: [
                      header,
                      Expanded(child: panes),
                    ],
                  ),
          ),
        ),
      );
    },
  );
}

Future<void> _shareLeaderboardCsv({
  required BuildContext context,
  required String csv,
}) async {
  try {
    await context.read<CsvShareService>().shareCsv(
      csv: csv,
      fileName: 'classifica-biliardino.csv',
      subject: 'Classifica Biliardino',
      text: 'Classifica Biliardino in CSV',
      sharePositionOrigin: _sharePositionOrigin(context),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('CSV pronto per la condivisione.')),
      );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Impossibile esportare il CSV: $error')),
      );
  }
}

Rect? _sharePositionOrigin(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox) {
    return null;
  }
  final origin = renderObject.localToGlobal(Offset.zero);
  return origin & renderObject.size;
}

class _LeaderboardPane extends StatelessWidget {
  const _LeaderboardPane({
    required this.ranked,
    required this.pairs,
    required this.sectionLabel,
    required this.metricLabel,
    required this.rowDetail,
    required this.emptyTitle,
    required this.emptyDescription,
    this.emptyIcon = Icons.leaderboard,
  });
  final List<RankingStats> ranked;
  final bool pairs;
  final String sectionLabel, emptyTitle, emptyDescription;
  final String Function(RankingStats) metricLabel, rowDetail;
  final IconData emptyIcon;
  @override
  Widget build(BuildContext context) {
    if (ranked.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 48, color: AppColors.ink),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: AppType.section,
              ),
              const SizedBox(height: 8),
              Text(
                emptyDescription,
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    final list = ListView.builder(
      key: PageStorageKey((sectionLabel, pairs)),
      padding: EdgeInsets.only(
        top: 8,
        bottom: 24 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: ranked.length > 3 ? ranked.length - 1 : 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return RankingPodium(
            top: ranked.take(3).toList(),
            metricLabel: metricLabel,
            onOpen: (id) => pairs
                ? openPairProfile(context, id)
                : openPlayerProfile(context, id),
          );
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
            child: Semantics(
              header: true,
              child: Text(sectionLabel, style: AppType.section),
            ),
          );
        }
        final i = index + 1;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: RankingRow(
            rank: i + 1,
            stats: ranked[i],
            metric: metricLabel(ranked[i]),
            detail: rowDetail(ranked[i]),
            onOpen: () => pairs
                ? openPairProfile(context, ranked[i].id)
                : openPlayerProfile(context, ranked[i].id),
          ),
        );
      },
    );
    return MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? list
        : RibbonBackdrop(child: list);
  }
}
