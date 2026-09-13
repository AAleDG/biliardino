import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/player_profile/player_profile_cubit.dart';
import '../cubits/player_profile/player_profile_state.dart';
import '../repositories/match_repository.dart';
import '../repositories/player_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/design/brand_header.dart';
import '../widgets/design/profile_artwork.dart';
import 'player_profile/profile_identity.dart';
import 'player_profile/profile_scene.dart';
import 'player_profile/profile_sections.dart';

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(playerId),
    create: (context) => PlayerProfileCubit(
      playerId: playerId,
      playerRepository: context.read<PlayerRepository>(),
      matchRepository: context.read<MatchRepository>(),
    ),
    child: BlocBuilder<PlayerProfileCubit, PlayerProfileState>(
      builder: (context, state) => _ProfileView(state: state),
    ),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.state});
  final PlayerProfileState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: brandAppBar(
      context,
      title: 'PROFILO',
      compactTitle: true,
      showArtwork: false,
    ),
    body: SafeArea(
      top: false,
      bottom: false,
      child: state.stats == null
          ? const Center(child: Text('Giocatore non trovato.'))
          : ProfileScene(
              builder: (context, scene) {
                final stats = state.stats!;
                Widget section(String title) => Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpace.section,
                    bottom: AppSpace.medium,
                  ),
                  child: ProfileSectionHeading(title),
                );
                return CustomScrollView(
                  key: const ValueKey('profile-scroll'),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.page,
                        AppSpace.medium,
                        AppSpace.page,
                        0,
                      ),
                      sliver: SliverList.list(
                        children: [
                          ProfileIdentity(stats: stats, scene: scene),
                          const SizedBox(height: AppSpace.page),
                          ProfileStatistics(
                            stats: stats,
                            results: state.profile.recentResults,
                          ),
                          section('INTESA E RIVALITÀ'),
                          ProfileRelationships(
                            profile: state.profile,
                            players: state.players,
                          ),
                          section('TESTA A TESTA'),
                          if (state.profile.headToHead.isEmpty)
                            const ProfilePanel(
                              child: Text(
                                'Nessun confronto diretto disponibile.',
                              ),
                            ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.page,
                      ),
                      sliver: SliverList.separated(
                        itemCount: state.profile.headToHead.length,
                        itemBuilder: (context, index) => ProfileHeadToHeadRow(
                          item: state.profile.headToHead[index],
                          players: state.players,
                        ),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpace.small),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.page,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: section('STORICO PERSONALE'),
                      ),
                    ),
                    if (state.personalMatches.isEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpace.page,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: ProfilePanel(
                            child: Text('Nessuna partita giocata.'),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.page,
                        ),
                        sliver: SliverList.separated(
                          itemCount: state.personalMatches.length,
                          itemBuilder: (context, index) => ProfileMatchRow(
                            key: ValueKey(
                              'profile-match-${state.personalMatches[index].id}',
                            ),
                            match: state.personalMatches[index],
                            players: state.players,
                            playerId: stats.player.id,
                          ),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpace.small),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: AppSpace.section,
                          bottom: MediaQuery.paddingOf(context).bottom,
                        ),
                        child:
                            MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                                MediaQuery.sizeOf(context).height < 450
                            ? const SizedBox(height: AppSpace.page)
                            : SizedBox(
                                height: 76,
                                child: ExcludeSemantics(
                                  child: IgnorePointer(
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        painter: scene == null
                                            ? null
                                            : ProfileFooterArtwork(
                                                scene: scene,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
    ),
  );
}
