import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/dashboard/dashboard_cubit.dart';
import '../cubits/dashboard/dashboard_state.dart';
import '../cubits/home/home_cubit.dart';
import '../cubits/new_match/new_match_cubit.dart';
import '../cubits/new_match/new_match_state.dart';
import '../models/player_stats.dart';
import '../navigation/app_navigation.dart';
import '../theme/app_theme.dart';

const homeHeroAssetPath =
    'design/south-africa-2010/assets/home-h2/png/home-hero-transparent.png';
const _homeHeroAspectRatio = 1516 / 1038;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) => SingleChildScrollView(
            key: const PageStorageKey('dashboard-scroll'),
            padding: const EdgeInsets.only(
              top: AppSpace.small,
              bottom: AppSpace.section,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.page),
                  child: _BrandLockup(),
                ),
                const SizedBox(height: AppSpace.small),
                const _HomeHero(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.page),
                  child: _StartMatchAction(),
                ),
                const SizedBox(height: AppSpace.medium),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page,
                  ),
                  child: _RecentMatchesSection(state: state),
                ),
                const SizedBox(height: AppSpace.medium),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page,
                  ),
                  child: _RankingSection(state: state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Biliardino. Gioca, sfida, vivi la passione.',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.skewX(-0.06),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'BILIARDINO',
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: AppType.event.copyWith(
                    color: AppColors.ink,
                    fontSize: 68,
                    height: .92,
                    letterSpacing: -.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.micro),
            Text(
              'GIOCA  •  SFIDA  •  VIVI LA PASSIONE',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: AppType.navigation.copyWith(
                color: AppColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AspectRatio(
        key: const ValueKey('dashboard-home-hero'),
        aspectRatio: _homeHeroAspectRatio,
        child: Image.asset(
          homeHeroAssetPath,
          width: double.infinity,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _StartMatchAction extends StatelessWidget {
  const _StartMatchAction();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NewMatchCubit, NewMatchState, bool>(
      selector: (state) => state.kickedOff && state.lastVictory == null,
      builder: (context, isActive) {
        final label = isActive ? 'RIPRENDI PARTITA' : 'INIZIA PARTITA';
        return Semantics(
          button: true,
          label: label.toLowerCase(),
          excludeSemantics: true,
          child: ElevatedButton(
            key: const ValueKey('dashboard-start-match'),
            onPressed: () =>
                context.read<HomeCubit>().select(HomeDestination.match),
            style:
                AppTheme.primaryButton(
                  background: AppColors.homeAction,
                  pressed: AppColors.homeActionPressed,
                ).copyWith(
                  minimumSize: const WidgetStatePropertyAll(
                    Size.fromHeight(72),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  textStyle: const WidgetStatePropertyAll(AppType.homeAction),
                  shape: const WidgetStatePropertyAll(StadiumBorder()),
                  side: WidgetStateProperty.resolveWith(
                    (states) => BorderSide(
                      color: states.contains(WidgetState.focused)
                          ? AppColors.ink
                          : AppColors.onPrimary,
                      width: 4,
                    ),
                  ),
                  elevation: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.pressed) ? 1 : 4,
                  ),
                  shadowColor: const WidgetStatePropertyAll(Color(0x40000000)),
                  surfaceTintColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 36),
                    const SizedBox(width: 14),
                    Text(label),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentMatchesSection extends StatelessWidget {
  const _RecentMatchesSection({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'ULTIME PARTITE',
      linkLabel: 'VEDI TUTTE',
      linkSemanticLabel: 'Apri tutto lo storico delle partite',
      onLinkPressed: () => openHistory(context),
      child: state.isLoading
          ? const _SectionLoading(label: 'Caricamento ultime partite')
          : state.recentMatches.isEmpty
          ? const _EmptySection(
              icon: Icons.sports_soccer_outlined,
              title: 'Nessuna partita registrata',
              description: 'Inizia una partita per popolare lo storico.',
            )
          : _GroupedPanel(
              children: [
                for (final summary in state.recentMatches)
                  _RecentMatchRow(
                    summary: summary,
                    onTap: () => openHistory(context),
                  ),
              ],
            ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  const _RankingSection({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'CLASSIFICA',
      linkLabel: 'VEDI TUTTI',
      linkSemanticLabel: 'Apri la classifica completa',
      onLinkPressed: () =>
          context.read<HomeCubit>().select(HomeDestination.leaderboard),
      child: state.isLoading
          ? const _SectionLoading(label: 'Caricamento classifica')
          : state.ranking.isEmpty
          ? const _EmptySection(
              icon: Icons.leaderboard_outlined,
              title: 'Classifica ancora vuota',
              description: 'I punti compariranno dopo la prima partita.',
            )
          : _GroupedPanel(
              children: [
                for (var i = 0; i < state.ranking.length; i++)
                  _RankingRow(
                    rank: i + 1,
                    stats: state.ranking[i],
                    onTap: () =>
                        openPlayerProfile(context, state.ranking[i].player.id),
                  ),
              ],
            ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.linkLabel,
    required this.linkSemanticLabel,
    required this.onLinkPressed,
    required this.child,
  });

  final String title;
  final String linkLabel;
  final String linkSemanticLabel;
  final VoidCallback onLinkPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final usesStackedHeader = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (usesStackedHeader) ...[
          Semantics(header: true, child: Text(title, style: AppType.section)),
          Align(
            alignment: Alignment.centerRight,
            child: _SectionLink(
              label: linkLabel,
              semanticLabel: linkSemanticLabel,
              onPressed: onLinkPressed,
            ),
          ),
        ] else
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpace.touch),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: AppType.section),
                  ),
                ),
                _SectionLink(
                  label: linkLabel,
                  semanticLabel: linkSemanticLabel,
                  onPressed: onLinkPressed,
                ),
              ],
            ),
          ),
        child,
      ],
    );
  }
}

class _SectionLink extends StatelessWidget {
  const _SectionLink({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSpace.touch, AppSpace.touch),
        padding: const EdgeInsets.only(left: 8),
        foregroundColor: AppColors.primary,
        textStyle: AppType.navigation,
      ),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.chevron_right, size: 18),
      label: Text(label, semanticsLabel: semanticLabel),
    );
  }
}

class _GroupedPanel extends StatelessWidget {
  const _GroupedPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: AppSpace.hairline,
                indent: 16,
                endIndent: 16,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _RecentMatchRow extends StatelessWidget {
  const _RecentMatchRow({required this.summary, required this.onTap});

  final DashboardMatchSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final match = summary.match;
    final matchup = '${summary.teamOneName} – ${summary.teamTwoName}';
    final score = '${match.t1Score} - ${match.t2Score}';
    final date = _compactItalianDate(match.playedAt);
    final winnerColor = match.winningTeam == 1
        ? AppColors.teamOne
        : AppColors.teamTwo;
    return Semantics(
      key: ValueKey('dashboard-match-${match.id}'),
      button: true,
      label: '$matchup, $score, $date. Apri lo storico.',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpace.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: winnerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      matchup,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.utility.copyWith(color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(score, style: AppType.bodyStrong),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    child: Text(
                      date,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      style: AppType.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.stats,
    required this.onTap,
  });

  final int rank;
  final PlayerStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('dashboard-ranking-${stats.player.id}'),
      button: true,
      label:
          'Posizione $rank, ${stats.player.name}, ${stats.points} punti. Apri il profilo.',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpace.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _RankMarker(rank: rank),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stats.player.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.utility.copyWith(color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${stats.points}', style: AppType.bodyStrong),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankMarker extends StatelessWidget {
  const _RankMarker({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => AppColors.yellow,
      2 => AppColors.disabledContainer,
      3 => AppColors.teamTwo,
      _ => AppColors.background,
    };
    final foreground = rank == 3 ? AppColors.onPrimary : AppColors.ink;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '$rank',
        textScaler: TextScaler.noScaling,
        style: AppType.utility.copyWith(color: foreground),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.page),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: AppSpace.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.bodyStrong),
                const SizedBox(height: AppSpace.micro),
                Text(
                  description,
                  style: AppType.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

String _compactItalianDate(DateTime date) {
  const months = [
    'gen',
    'feb',
    'mar',
    'apr',
    'mag',
    'giu',
    'lug',
    'ago',
    'set',
    'ott',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
