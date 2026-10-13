import '../../ranking_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/leaderboard/leaderboard_cubit.dart';
import '../../../cubits/leaderboard/leaderboard_state.dart';
import '../../../models/game_match.dart';
import '../../../models/player_stats.dart';
import '../../../models/team_leaderboard_stats.dart';
import '../../../services/csv_share_service.dart';
import '../../../services/leaderboard_csv_service.dart';
import '../theme/italia90_tokens.dart';
import '../widgets/avatar.dart';
import '../widgets/design/ranking_podium.dart';
import '../widgets/design/ranking_avatar.dart';
import '../widgets/design/ranking_metrics.dart';
import '../widgets/italia90_components.dart';
import '../widgets/italia90_page.dart';
import '../widgets/italia_graphic_backdrop.dart';
import 'leaderboard/ranking_row.dart';
import '../../../navigation/app_navigation.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(
    BuildContext context,
  ) =>
      BlocBuilder<LeaderboardCubit, LeaderboardState>(
        builder: (context, state) {
          final rankedByPoints = state.general;
          final rankedByGoals = state.scorers;
          final podiumByPoints = state.selectedMode == MatchMode.twoVsTwo
              ? state.teamGeneral
                  .take(3)
                  .map(
                    (stats) => RankingPodiumEntry.team(
                      stats,
                      metric: _teamPointsLabel(stats.points),
                    ),
                  )
                  .toList(growable: false)
              : rankedByPoints
                  .take(3)
                  .map(
                    (stats) => RankingPodiumEntry.player(
                      stats,
                      metric: _pointsLabel(stats),
                    ),
                  )
                  .toList(growable: false);
          final podiumByGoals = state.selectedMode == MatchMode.twoVsTwo
              ? state.teamScorers
                  .take(3)
                  .map(
                    (stats) => RankingPodiumEntry.team(
                      stats,
                      metric: _teamGoalsLabel(stats.goalsScored),
                    ),
                  )
                  .toList(growable: false)
              : rankedByGoals
                  .take(3)
                  .map(
                    (stats) => RankingPodiumEntry.player(
                      stats,
                      metric: _goalsLabel(stats),
                    ),
                  )
                  .toList(growable: false);
          final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
          final header = _LeaderboardHeader(
            largeText: largeText,
            selectedMode: state.selectedMode,
            canExport: state.selectedMode == MatchMode.twoVsTwo
                ? state.teamGeneral.isNotEmpty
                : rankedByPoints.isNotEmpty,
            ranked: rankedByPoints,
            teams: state.selectedMode == MatchMode.twoVsTwo
                ? state.teamGeneral
                : null,
            onModeChanged: context.read<LeaderboardCubit>().selectMode,
          );
          final panes = TabBarView(
            children: [
              _LeaderboardPane(
                ranked: rankedByPoints,
                podiumEntries: podiumByPoints,
                teamRanked: state.selectedMode == MatchMode.twoVsTwo
                    ? state.teamGeneral
                    : const [],
                sectionLabel: 'CLASSIFICA COMPLETA',
                emptyTitle: 'Nessuna partita giocata',
                emptyDescription:
                    'Registra una partita per vedere la classifica.',
              ),
              _LeaderboardPane(
                ranked: rankedByGoals,
                podiumEntries: podiumByGoals,
                teamRanked: state.selectedMode == MatchMode.twoVsTwo
                    ? state.teamScorers
                    : const [],
                sectionLabel: 'CLASSIFICA MARCATORI',
                emptyTitle: 'Nessun marcatore disponibile',
                emptyDescription:
                    'I gol compariranno qui dalle partite salvate con assegnazione marcatore.',
                emptyIcon: Icons.sports_soccer,
              ),
            ],
          );
          final useScrollableHeader =
              largeText || MediaQuery.sizeOf(context).height < 500;
          return RankingTabs(
            child: Scaffold(
              body: ItaliaGraphicBackdrop(
                variant: ItaliaBackdropVariant.working,
                child: SafeArea(
                  child: useScrollableHeader
                      ? NestedScrollView(
                          key: const ValueKey('leaderboard-shell-scroll'),
                          headerSliverBuilder: (context, innerBoxIsScrolled) =>
                              [
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
            ),
          );
        },
      );
}

String _pointsLabel(PlayerStats stats) => '${stats.points} pt';

String _goalsLabel(PlayerStats stats) => '${stats.goalsScored} gol';

String _teamPointsLabel(int points) => '$points pt';

String _teamGoalsLabel(int goals) => '$goals gol';

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({
    required this.largeText,
    required this.selectedMode,
    required this.canExport,
    required this.ranked,
    required this.teams,
    required this.onModeChanged,
  });

  final bool largeText;
  final MatchMode selectedMode;
  final bool canExport;
  final List<PlayerStats> ranked;
  final List<TeamLeaderboardStats>? teams;
  final ValueChanged<MatchMode> onModeChanged;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ItaliaCompactMasthead(
              semanticsKey: ValueKey('leaderboard-masthead'),
              footballKey: ValueKey('leaderboard-brand-football'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CLASSIFICA',
                        style: Italia90.display.copyWith(
                          fontSize: 56,
                          height: 0.96,
                        ),
                      ),
                    ),
                  ),
                ),
                Builder(
                  builder: (buttonContext) => IconButton(
                    key: const ValueKey('leaderboard-export-csv'),
                    icon: const Icon(Icons.ios_share),
                    tooltip: 'Esporta CSV',
                    onPressed: !canExport
                        ? null
                        : () => _shareLeaderboardCsv(
                              context: buttonContext,
                              ranked: ranked,
                              teams: teams,
                            ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: _LeaderboardTabSelector(largeText: largeText),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _LeaderboardModeSelector(
              selectedMode: selectedMode,
              largeText: largeText,
              onChanged: onModeChanged,
            ),
          ),
        ],
      );
}

class _LeaderboardModeSelector extends StatelessWidget {
  const _LeaderboardModeSelector({
    required this.selectedMode,
    required this.largeText,
    required this.onChanged,
  });

  final MatchMode selectedMode;
  final bool largeText;
  final ValueChanged<MatchMode> onChanged;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largeText ? 320 : 236),
        child: Semantics(
          container: true,
          label: 'Modalità classifica',
          child: SegmentedButton<MatchMode>(
            key: const ValueKey('leaderboard-mode-selector'),
            segments: const [
              ButtonSegment<MatchMode>(
                value: MatchMode.twoVsTwo,
                label: Text('2vs2'),
              ),
              ButtonSegment<MatchMode>(
                value: MatchMode.oneVsOne,
                label: Text('1vs1'),
              ),
            ],
            selected: {selectedMode},
            onSelectionChanged: (selection) => onChanged(selection.single),
            showSelectedIcon: false,
            style: ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(0, largeText ? 56 : 36)),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: largeText ? 12 : 18),
              ),
              textStyle: const WidgetStatePropertyAll(Italia90.label),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Italia90.teamOne
                    : Italia90.panel,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : Italia90.ink,
              ),
              side: const WidgetStatePropertyAll(
                BorderSide(color: Italia90.outline),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Italia90.controlRadius),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Keeps both ranking tabs fully readable at accessibility-extra-large sizes.
///
/// The ordinary tab bar remains unchanged for the approved normal layout. At
/// large text it becomes a vertical pair of full-width actions, while the
/// existing DefaultTabController and TabBarView continue to own navigation.
class _LeaderboardTabSelector extends StatelessWidget {
  const _LeaderboardTabSelector({required this.largeText});

  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!largeText) {
          return Material(
            color: Italia90.panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Italia90.controlRadius),
              side: const BorderSide(color: Italia90.outline),
            ),
            child: const TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Italia90.ink,
              labelStyle: Italia90.label,
              indicator: BoxDecoration(
                color: Italia90.teamOne,
                borderRadius: BorderRadius.all(
                  Radius.circular(Italia90.controlRadius),
                ),
              ),
              tabs: [
                Tab(text: 'Generale', height: 40),
                Tab(text: 'Marcatori', height: 40),
              ],
            ),
          );
        }

        return DecoratedBox(
          decoration: ShapeDecoration(
            color: Italia90.panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Italia90.controlRadius),
              side: const BorderSide(color: Italia90.outline),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _largeTextTab(
                  controller: controller,
                  index: 0,
                  label: 'Generale',
                ),
                const SizedBox(height: 4),
                _largeTextTab(
                  controller: controller,
                  index: 1,
                  label: 'Marcatori',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _largeTextTab({
    required TabController controller,
    required int index,
    required String label,
  }) {
    final selected = controller.index == index;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      hint: selected ? 'Scheda selezionata' : 'Mostra la scheda $label',
      onTap: () => controller.animateTo(index),
      child: ExcludeSemantics(
        child: Material(
          color: selected ? Italia90.teamOne : Italia90.panel,
          borderRadius: BorderRadius.circular(Italia90.controlRadius),
          child: InkWell(
            onTap: () => controller.animateTo(index),
            borderRadius: BorderRadius.circular(Italia90.controlRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Italia90.label.copyWith(
                  color: selected ? Colors.white : Italia90.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _rankColor(int rank) => switch (rank) {
      1 => Italia90.red,
      2 => Italia90.teamOne,
      3 => Italia90.teamTwo,
      _ => Italia90.primary,
    };

class _LeaderboardPane extends StatelessWidget {
  const _LeaderboardPane({
    required this.ranked,
    required this.podiumEntries,
    this.teamRanked = const [],
    required this.sectionLabel,
    required this.emptyTitle,
    required this.emptyDescription,
    this.emptyIcon = Icons.leaderboard,
  });
  final List<PlayerStats> ranked;
  final List<RankingPodiumEntry> podiumEntries;
  final List<TeamLeaderboardStats> teamRanked;
  final String sectionLabel;
  final String emptyTitle;
  final String emptyDescription;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (ranked.isEmpty && teamRanked.isEmpty) {
      return ItaliaEmptyState(
        title: emptyTitle,
        description: emptyDescription,
        icon: emptyIcon,
      );
    }
    return SingleChildScrollView(
      key: const ValueKey('leaderboard-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RankingPodium(
            entries: podiumEntries,
            // The impact painter is still a review candidate. The approved
            // poster backdrop and live Flutter cards provide the production
            // composition until that artwork receives explicit approval.
            showArtwork: false,
            onOpen: (id) {
              if (teamRanked.any((stats) => stats.id == id)) {
                openPairProfile(context, id);
              } else {
                openPlayerProfile(context, id);
              }
            },
          ),
          const SizedBox(height: 6),
          _LeaderboardLedger(
            ranked: ranked,
            teamRanked: teamRanked,
            sectionLabel: sectionLabel,
          ),
        ],
      ),
    );
  }
}

// Kept as a compatibility implementation for archived Italia previews.
// ignore: unused_element
class _Podium extends StatelessWidget {
  const _Podium({required this.top, required this.metricLabel});

  final List<PlayerStats> top;
  final String Function(PlayerStats) metricLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (top.isEmpty) {
            return const SizedBox.shrink();
          }
          final stacked = constraints.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(16) > 22;
          Widget place(int index) => _PodiumPlace(
                rank: index + 1,
                stats: top[index],
                metricLabel: metricLabel,
              );
          if (stacked) {
            return Column(
              children: [
                for (var i = 0; i < top.length; i++)
                  Padding(
                    padding:
                        EdgeInsets.only(bottom: i == top.length - 1 ? 0 : 12),
                    child: place(i),
                  ),
              ],
            );
          }
          final order = top.length == 3
              ? [1, 0, 2]
              : [for (var i = 0; i < top.length; i++) i];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final i in order)
                Expanded(
                  flex: i == 0 ? 10 : 9,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4, i == 0 ? 18 : 0, 4, 0),
                    child: SizedBox(width: double.infinity, child: place(i)),
                  ),
                ),
            ],
          );
        },
      );
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.rank,
    required this.stats,
    required this.metricLabel,
  });

  final int rank;
  final PlayerStats stats;
  final String Function(PlayerStats) metricLabel;

  @override
  Widget build(BuildContext context) {
    final cardColor = _rankColor(rank);
    final onCard = rank == 3 ? Italia90.ink : Colors.white;
    final avatarBackground = rank == 3 ? Italia90.ink : Colors.white;

    return KeyedSubtree(
      key: ValueKey('leaderboard-winner-${stats.player.id}'),
      child: Semantics(
        key: ValueKey('leaderboard-podium-${stats.player.id}'),
        container: true,
        button: true,
        enabled: true,
        label: 'Posizione $rank: ${stats.player.name}. ${metricLabel(stats)}.',
        onTap: () => openPlayerProfile(context, stats.player.id),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$rank',
                style: Italia90.display.copyWith(fontSize: 52, height: 0.9),
              ),
              const SizedBox(height: 4),
              Material(
                key: ValueKey('leaderboard-podium-card-${stats.player.id}'),
                color: cardColor,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Italia90.panelRadius),
                ),
                child: InkWell(
                  onTap: () => openPlayerProfile(context, stats.player.id),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: rank == 1 ? 206 : 164,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (rank == 1) ...[
                                Icon(
                                  Icons.emoji_events_outlined,
                                  color: onCard,
                                  size: 42,
                                ),
                                const SizedBox(height: 2),
                              ],
                              PlayerAvatar(
                                name: stats.player.name,
                                size: rank == 1 ? 68 : 60,
                                color: avatarBackground,
                                foregroundColor: cardColor,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                stats.player.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Italia90.title.copyWith(
                                  color: onCard,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _PodiumMetric(
                        label: metricLabel(stats),
                        color: Italia90.surface,
                      ),
                      SizedBox(height: 7, child: ColoredBox(color: cardColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumMetric extends StatelessWidget {
  const _PodiumMetric({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final parts = label.split(' ');
    final number = parts.first;
    final suffix = parts.skip(1).join(' ');
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Italia90.ink),
            children: [
              TextSpan(
                text: number,
                style: Italia90.display.copyWith(fontSize: 48, height: 0.9),
              ),
              TextSpan(
                text: ' $suffix',
                style: Italia90.title.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardLedger extends StatelessWidget {
  const _LeaderboardLedger({
    required this.ranked,
    required this.teamRanked,
    required this.sectionLabel,
  });

  final List<PlayerStats> ranked;
  final List<TeamLeaderboardStats> teamRanked;
  final String sectionLabel;

  @override
  Widget build(BuildContext context) => Material(
        key: const ValueKey('leaderboard-ledger'),
        color: Italia90.panel,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Italia90.panelRadius),
          side: const BorderSide(color: Italia90.outline),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Text(
                    sectionLabel,
                    style: Italia90.heading.copyWith(fontSize: 18),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(16) > 22;
                if (teamRanked.isNotEmpty) {
                  return _TeamLedgerRows(ranked: teamRanked, compact: compact);
                }
                return compact
                    ? _CompactLedgerRows(ranked: ranked)
                    : _WideLedgerRows(ranked: ranked);
              },
            ),
          ],
        ),
      );
}

class _TeamLedgerRows extends StatelessWidget {
  const _TeamLedgerRows({required this.ranked, required this.compact});

  final List<TeamLeaderboardStats> ranked;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          compact
              ? const _CompactTeamLedgerHeader()
              : const _WideLedgerHeader(),
          for (var i = 0; i < ranked.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _TeamLedgerRow(
              rank: i + 1,
              stats: ranked[i],
              compact: compact,
              onOpen: () => openPairProfile(context, ranked[i].id),
            ),
          ],
        ],
      );
}

class _TeamLedgerRow extends StatelessWidget {
  const _TeamLedgerRow({
    required this.rank,
    required this.stats,
    required this.compact,
    required this.onOpen,
  });

  final int rank;
  final TeamLeaderboardStats stats;
  final bool compact;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
        key: ValueKey('leaderboard-row-${stats.id}'),
        container: true,
        button: true,
        enabled: true,
        hint: 'Apri il profilo della coppia',
        label: 'Posizione $rank: ${stats.name}. ${stats.games} partite, '
            '${stats.goalsScored} gol, ${stats.wins} vittorie, ${stats.points} punti.',
        onTap: onOpen,
        child: ExcludeSemantics(
          child: InkWell(
            onTap: onOpen,
            child: compact ? _compactContent() : _wideContent(),
          ),
        ),
      );

  Widget _wideContent() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 3, 14, 3),
        child: Row(
          children: [
            _TeamRankMarker(rank: rank, compact: false),
            const SizedBox(width: 8),
            RankingAvatar(name: _avatarName, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                stats.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Italia90.title.copyWith(fontSize: 16),
              ),
            ),
            _TeamMetric(
              key: ValueKey('leaderboard-${stats.id}-pg'),
              value: stats.games.toString(),
            ),
            _TeamMetric(
              key: ValueKey('leaderboard-${stats.id}-gol'),
              value: stats.goalsScored.toString(),
            ),
            _TeamMetric(
              key: ValueKey('leaderboard-${stats.id}-v'),
              value: stats.wins.toString(),
            ),
            _TeamMetric(
              key: ValueKey('leaderboard-${stats.id}-pt'),
              value: stats.points.toString(),
              emphasized: true,
            ),
          ],
        ),
      );

  Widget _compactContent() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _TeamRankMarker(rank: rank, compact: true),
                const SizedBox(width: 8),
                RankingAvatar(name: _avatarName, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stats.name,
                    style: Italia90.title.copyWith(fontSize: 18),
                  ),
                ),
              ],
            ),
            RankingMetrics(
              id: stats.id,
              metrics: [
                RankingMetricSpec(
                  keySuffix: 'pg',
                  label: 'PG',
                  value: stats.games.toString(),
                ),
                RankingMetricSpec(
                  keySuffix: 'gol',
                  label: 'GOL',
                  value: stats.goalsScored.toString(),
                ),
                RankingMetricSpec(
                  keySuffix: 'v',
                  label: 'V',
                  value: stats.wins.toString(),
                ),
                RankingMetricSpec(
                  keySuffix: 'pt',
                  label: 'PT',
                  value: stats.points.toString(),
                  emphasized: true,
                ),
              ],
            ),
          ],
        ),
      );

  String get _avatarName =>
      stats.players.isEmpty ? stats.name : stats.players.first.name;
}

class _CompactTeamLedgerHeader extends StatelessWidget {
  const _CompactTeamLedgerHeader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Align(alignment: Alignment.centerLeft, child: Text('GIOCATORE')),
      );
}

class _TeamRankMarker extends StatelessWidget {
  const _TeamRankMarker({required this.rank, required this.compact});

  final int rank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => Italia90.teamTwo,
      2 => Italia90.outline,
      3 => Italia90.red,
      _ => Italia90.primary,
    };
    final foreground = rank == 2 || rank == 1 ? Italia90.ink : Colors.white;
    return Container(
      width: compact ? 28 : 30,
      height: compact ? 28 : 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$rank',
          style: Italia90.label.copyWith(color: foreground, fontSize: 15),
        ),
      ),
    );
  }
}

class _TeamMetric extends StatelessWidget {
  const _TeamMetric({super.key, required this.value, this.emphasized = false});

  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 34,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: Italia90.body.copyWith(
              fontSize: 17,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
              color: emphasized ? Italia90.teamOne : Italia90.ink,
            ),
          ),
        ),
      );
}

class _WideLedgerRows extends StatelessWidget {
  const _WideLedgerRows({required this.ranked});

  final List<PlayerStats> ranked;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const _WideLedgerHeader(),
          for (var i = 0; i < ranked.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            RankingRow(
              rank: i + 1,
              stats: ranked[i],
              metric: '${ranked[i].points} pt',
              detail:
                  '${ranked[i].games} partite, ${ranked[i].goalsScored} gol, '
                  '${ranked[i].wins} vittorie',
              onOpen: () => openPlayerProfile(context, ranked[i].player.id),
            ),
          ],
        ],
      );
}

class _WideLedgerHeader extends StatelessWidget {
  const _WideLedgerHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Row(
          children: [
            const SizedBox(width: 28),
            const SizedBox(width: 8),
            const SizedBox(width: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'GIOCATORE',
                style: Italia90.label
                    .copyWith(color: Italia90.muted, fontSize: 14),
              ),
            ),
            for (final label in ['PG', 'GOL', 'V', 'PT'])
              SizedBox(
                key: ValueKey('leaderboard-header-${label.toLowerCase()}'),
                width: 34,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Italia90.label.copyWith(
                    color: Italia90.muted,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      );
}

class _CompactLedgerRows extends StatelessWidget {
  const _CompactLedgerRows({required this.ranked});

  final List<PlayerStats> ranked;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const SizedBox(width: 28),
                const SizedBox(width: 8),
                const SizedBox(width: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GIOCATORE',
                    style: Italia90.label.copyWith(
                      color: Italia90.muted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < ranked.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            RankingRow(
              rank: i + 1,
              stats: ranked[i],
              metric: '${ranked[i].points} pt',
              detail:
                  '${ranked[i].games} partite, ${ranked[i].goalsScored} gol, '
                  '${ranked[i].wins} vittorie',
              onOpen: () => openPlayerProfile(context, ranked[i].player.id),
            ),
          ],
        ],
      );
}

// The responsive row now lives in the leaderboard feature module.
// ignore: unused_element
class _CompactLeaderRow extends StatelessWidget {
  const _CompactLeaderRow({required this.rank, required this.stats});

  final int rank;
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) => Semantics(
        key: ValueKey('leaderboard-row-${stats.player.id}'),
        container: true,
        button: true,
        enabled: true,
        label:
            'Posizione $rank: ${stats.player.name}. ${stats.games} partite, ${stats.goalsScored} gol, ${stats.wins} vittorie, ${stats.points} punti.',
        onTap: () => openPlayerProfile(context, stats.player.id),
        child: ExcludeSemantics(
          child: InkWell(
            onTap: () => openPlayerProfile(context, stats.player.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$rank',
                          textAlign: TextAlign.center,
                          style: Italia90.heading.copyWith(
                            color: Italia90.ink,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PlayerAvatar(
                        name: stats.player.name,
                        size: 40,
                        color: Italia90.avatarNeutral,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stats.player.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Italia90.title.copyWith(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 76, top: 8),
                    child: Row(
                      children: [
                        _CompactMetric(
                          key: ValueKey('leaderboard-${stats.player.id}-pg'),
                          label: 'PG',
                          value: stats.games.toString(),
                        ),
                        _CompactMetric(
                          key: ValueKey('leaderboard-${stats.player.id}-gol'),
                          label: 'GOL',
                          value: stats.goalsScored.toString(),
                        ),
                        _CompactMetric(
                          key: ValueKey('leaderboard-${stats.player.id}-v'),
                          label: 'V',
                          value: stats.wins.toString(),
                        ),
                        _CompactMetric(
                          key: ValueKey('leaderboard-${stats.player.id}-pt'),
                          label: 'PT',
                          value: stats.points.toString(),
                          emphasized: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  Italia90.label.copyWith(color: Italia90.muted, fontSize: 11),
            ),
            Text(
              value,
              style: Italia90.body.copyWith(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
                color: Italia90.ink,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
}

// The responsive row now lives in the leaderboard feature module.
// ignore: unused_element
class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.rank, required this.stats});
  final int rank;
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) => Semantics(
        key: ValueKey('leaderboard-row-${stats.player.id}'),
        container: true,
        button: true,
        enabled: true,
        label:
            'Posizione $rank: ${stats.player.name}. ${stats.games} partite, ${stats.goalsScored} gol, ${stats.wins} vittorie, ${stats.points} punti.',
        onTap: () => openPlayerProfile(context, stats.player.id),
        child: ExcludeSemantics(
          child: InkWell(
            onTap: () => openPlayerProfile(context, stats.player.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$rank',
                      style: Italia90.body.copyWith(
                        color: Italia90.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PlayerAvatar(
                    name: stats.player.name,
                    size: 40,
                    color: Italia90.avatarNeutral,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.player.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Italia90.title.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  _MetricValue(
                    key: ValueKey('leaderboard-${stats.player.id}-pg'),
                    value: stats.games.toString(),
                  ),
                  _MetricValue(
                    key: ValueKey('leaderboard-${stats.player.id}-gol'),
                    value: stats.goalsScored.toString(),
                  ),
                  _MetricValue(
                    key: ValueKey('leaderboard-${stats.player.id}-v'),
                    value: stats.wins.toString(),
                  ),
                  _MetricValue(
                    key: ValueKey('leaderboard-${stats.player.id}-pt'),
                    value: stats.points.toString(),
                    emphasized: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _MetricValue extends StatelessWidget {
  const _MetricValue({super.key, required this.value, this.emphasized = false});

  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 34,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: Italia90.body.copyWith(
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
              color: Italia90.ink,
              fontSize: 18,
            ),
          ),
        ),
      );
}

Future<void> _shareLeaderboardCsv({
  required BuildContext context,
  required List<PlayerStats> ranked,
  List<TeamLeaderboardStats>? teams,
}) async {
  try {
    final csv = teams == null
        ? LeaderboardCsvService.build(ranked)
        : LeaderboardCsvService.buildPairs(teams);
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
