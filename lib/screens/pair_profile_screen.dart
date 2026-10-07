import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubits/pair_profile/pair_profile_cubit.dart';
import '../cubits/pair_profile/pair_profile_state.dart';
import '../navigation/app_navigation.dart';
import '../repositories/match_repository.dart';
import '../repositories/player_repository.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design/brand_header.dart';
import '../widgets/design/ranking_identity.dart';
import '../widgets/design/ranking_badges.dart';
import 'player_profile/profile_sections.dart';

class PairProfileScreen extends StatelessWidget {
  const PairProfileScreen({super.key, required this.pairId});
  final String pairId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(pairId),
    create: (context) => PairProfileCubit(
      pairId: pairId,
      playerRepository: context.read<PlayerRepository>(),
      matchRepository: context.read<MatchRepository>(),
    ),
    child: BlocBuilder<PairProfileCubit, PairProfileState>(
      builder: (context, state) => _PairView(state: state),
    ),
  );
}

class _PairView extends StatelessWidget {
  const _PairView({required this.state});
  final PairProfileState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    return Scaffold(
      appBar: brandAppBar(
        context,
        title: 'PROFILO COPPIA',
        compactTitle: true,
        showArtwork: false,
      ),
      body: SafeArea(
        top: false,
        child: profile == null
            ? const Center(child: Text('Coppia non trovata.'))
            : CustomScrollView(
                key: const ValueKey('pair-profile-scroll'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpace.page),
                    sliver: SliverList.list(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.yellow,
                            borderRadius: BorderRadius.circular(
                              AppRadius.panel,
                            ),
                          ),
                          padding: const EdgeInsets.all(AppSpace.page),
                          child: Column(
                            children: [
                              RankingIdentity(
                                names: profile.stats.memberNames,
                                size: 64,
                              ),
                              const SizedBox(height: AppSpace.medium),
                              Text(
                                profile.stats.name,
                                textAlign: TextAlign.center,
                                style: AppType.screen,
                              ),
                              Text(
                                '#${profile.rank} · ${profile.stats.points} pt',
                                style: AppType.section,
                              ),
                              Text(
                                'Insieme dal ${DateFormat('dd/MM/yyyy').format(profile.togetherSince)}',
                                style: AppType.caption,
                              ),
                              if (profile.stats.badges.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpace.medium,
                                  ),
                                  child: ProfilePanel(
                                    padding: const EdgeInsets.all(
                                      AppSpace.small,
                                    ),
                                    child: RankingBadges(
                                      badges: profile.stats.badges,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.page),
                        ProfileStatistics(
                          stats: profile.stats,
                          results: profile.recentResults,
                          heading: 'STATISTICHE DI COPPIA',
                        ),
                        const SizedBox(height: AppSpace.section),
                        const ProfileSectionHeading('I GIOCATORI'),
                        const SizedBox(height: AppSpace.medium),
                        for (final player in profile.stats.players)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpace.small,
                            ),
                            child: ProfilePanel(
                              padding: EdgeInsets.zero,
                              child: Material(
                                color: AppColors.surface,
                                child: ListTile(
                                  key: ValueKey('pair-member-${player.id}'),
                                  title: Text(
                                    player.name,
                                    style: AppType.player,
                                  ),
                                  subtitle: Text(
                                    player.isArchived
                                        ? 'Archiviato'
                                        : player.isPresent
                                        ? 'Presente'
                                        : 'Assente',
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.primary,
                                  ),
                                  onTap: () =>
                                      openPlayerProfile(context, player.id),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpace.section),
                        const ProfileSectionHeading('AVVERSARI'),
                        const SizedBox(height: AppSpace.medium),
                        for (final opponent in profile.opponents)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpace.small,
                            ),
                            child: ProfilePanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opponent.playerIds
                                        .map(
                                          (id) => StatsService.playerName(
                                            state.players,
                                            id,
                                          ),
                                        )
                                        .join(' + '),
                                    style: AppType.player,
                                  ),
                                  Text(
                                    '${opponent.games} partite · ${opponent.wins}V · ${opponent.losses}P',
                                    style: AppType.caption,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpace.section),
                        const ProfileSectionHeading('PARTITE INSIEME'),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: profile.matches.length,
                      itemBuilder: (context, index) {
                        final match = profile.matches[index];
                        final memberIds = profile.stats.players
                            .map((p) => p.id)
                            .toSet();
                        final firstSide = memberIds.contains(match.t1p1);
                        final won = match.winningTeam == (firstSide ? 1 : 2);
                        final goals = match.scorerIds
                            .where(memberIds.contains)
                            .length;
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpace.small,
                          ),
                          child: ProfilePanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${won ? 'Vittoria' : 'Sconfitta'} · ${match.t1Score}-${match.t2Score}',
                                  style: AppType.bodyStrong,
                                ),
                                Text(
                                  '${DateFormat('dd/MM/yyyy HH:mm').format(match.playedAt)} · $goals gol',
                                  style: AppType.caption,
                                ),
                                Text(
                                  'vs ${(firstSide ? match.team2 : match.team1).map((id) => StatsService.playerName(state.players, id)).join(' + ')}',
                                  style: AppType.caption,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
