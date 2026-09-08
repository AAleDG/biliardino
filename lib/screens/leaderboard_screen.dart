import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/leaderboard/leaderboard_cubit.dart';
import '../cubits/leaderboard/leaderboard_state.dart';
import '../models/player_stats.dart';
import '../services/csv_share_service.dart';
import '../services/leaderboard_csv_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/design/brand_header.dart';
import '../widgets/design/ranking_podium.dart';
import '../widgets/design/ranking_badges.dart';
import 'player_profile_screen.dart';

void _openPlayerProfile(BuildContext context, String playerId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlayerProfileScreen(playerId: playerId),
    ),
  );
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LeaderboardCubit, LeaderboardState>(
    builder: (context, state) {
      final rankedByPoints = state.stats.where((s) => s.games > 0).toList();
      final rankedByGoals = state.stats.where((s) => s.goalsScored > 0).toList()
        ..sort((a, b) {
          final byGoals = b.goalsScored.compareTo(a.goalsScored);
          if (byGoals != 0) return byGoals;
          final byGames = b.games.compareTo(a.games);
          if (byGames != 0) return byGames;
          return a.player.name.toLowerCase().compareTo(
            b.player.name.toLowerCase(),
          );
        });
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: brandAppBar(
            context,
            title: 'CLASSIFICA',
            actions: [
              Builder(
                builder: (buttonContext) => IconButton(
                  key: const ValueKey('leaderboard-export-csv'),
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'Esporta CSV',
                  onPressed: rankedByPoints.isEmpty
                      ? null
                      : () => _shareLeaderboardCsv(
                          context: buttonContext,
                          ranked: rankedByPoints,
                        ),
                ),
              ),
            ],
          ),
          body: RibbonBackdrop(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: TabBar(
                      isScrollable:
                          MediaQuery.textScalerOf(context).scale(1) > 1.3,
                      tabAlignment:
                          MediaQuery.textScalerOf(context).scale(1) > 1.3
                          ? TabAlignment.start
                          : TabAlignment.fill,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppColors.onPrimary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: AppType.bodyStrong,
                      unselectedLabelStyle: AppType.bodyStrong,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      tabs: const [
                        Tab(text: 'Generale'),
                        Tab(text: 'Marcatori'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _LeaderboardPane(
                        ranked: rankedByPoints,
                        sectionLabel: 'CLASSIFICA COMPLETA',
                        podiumMetric: (stats) => '${stats.points} pt',
                        rowMetric: (stats) => '${stats.points}',
                        rowDetail: (stats) =>
                            '${stats.wins}V · ${stats.losses}P · ${stats.games} partite',
                        emptyTitle: 'Nessuna partita giocata',
                        emptyDescription:
                            'Registra una partita per vedere la classifica.',
                      ),
                      _LeaderboardPane(
                        ranked: rankedByGoals,
                        sectionLabel: 'CLASSIFICA MARCATORI',
                        podiumMetric: (stats) => '${stats.goalsScored} gol',
                        rowMetric: (stats) => '${stats.goalsScored}',
                        rowDetail: (stats) =>
                            '${stats.games} partite · ${stats.wins} vittorie',
                        emptyTitle: 'Nessun marcatore disponibile',
                        emptyDescription:
                            'I gol compariranno qui dalle partite salvate con assegnazione marcatore.',
                        emptyIcon: Icons.sports_soccer,
                      ),
                    ],
                  ),
                ),
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
  required List<PlayerStats> ranked,
}) async {
  try {
    final csv = LeaderboardCsvService.build(ranked);
    await CsvShareService.platform().shareCsv(
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
    required this.sectionLabel,
    required this.podiumMetric,
    required this.rowMetric,
    required this.rowDetail,
    required this.emptyTitle,
    required this.emptyDescription,
    this.emptyIcon = Icons.leaderboard,
  });
  final List<PlayerStats> ranked;
  final String sectionLabel, emptyTitle, emptyDescription;
  final String Function(PlayerStats) podiumMetric, rowMetric, rowDetail;
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        RankingPodium(
          top: ranked.take(3).toList(),
          metricLabel: podiumMetric,
          onOpen: (id) => _openPlayerProfile(context, id),
        ),
        if (ranked.length > 3) ...[
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(sectionLabel, style: AppType.section),
          ),
          const SizedBox(height: 10),
          for (var i = 3; i < ranked.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LeaderRow(
                rank: i + 1,
                stats: ranked[i],
                metric: rowMetric(ranked[i]),
                detail: rowDetail(ranked[i]),
              ),
            ),
        ],
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.stats,
    required this.metric,
    required this.detail,
  });
  final int rank;
  final PlayerStats stats;
  final String metric, detail;
  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('leaderboard-row-${stats.player.id}'),
    container: true,
    button: true,
    enabled: true,
    label: 'Posizione $rank: ${stats.player.name}. $metric. $detail.',
    onTap: () => _openPlayerProfile(context, stats.player.id),
    child: ExcludeSemantics(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        child: InkWell(
          onTap: () => _openPlayerProfile(context, stats.player.id),
          borderRadius: BorderRadius.circular(AppRadius.panel),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$rank', style: AppType.section),
                const SizedBox(width: 12),
                if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
                  PlayerAvatar(name: stats.player.name),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats.player.name, style: AppType.player),
                      Text(
                        detail,
                        style: AppType.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (stats.badges.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: RankingBadges(badges: stats.badges),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(metric, style: AppType.section),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
