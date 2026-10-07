import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/player_profile/player_profile_cubit.dart';
import '../../../cubits/player_profile/player_profile_state.dart';
import '../../../repositories/match_repository.dart';
import '../../../repositories/player_repository.dart';
import '../theme/italia90_tokens.dart';
import '../widgets/italia90_page.dart';
import 'player_profile/profile_identity.dart';
import 'player_profile/profile_sections.dart';

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context) => BlocProvider<PlayerProfileCubit>(
    key: ValueKey(playerId),
    create: (ctx) => PlayerProfileCubit(
      playerId: playerId,
      playerRepository: ctx.read<PlayerRepository>(),
      matchRepository: ctx.read<MatchRepository>(),
    ),
    child: const _ProfileView(),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PlayerProfileCubit, PlayerProfileState>(
    builder: (context, state) {
      if (state.stats == null) {
        return const ItaliaPage(
          title: 'PROFILO',
          showBack: true,
          mastheadKey: ValueKey('profile-masthead'),
          footballKey: ValueKey('profile-brand-football'),
          child: ItaliaEmptyState(
            title: 'Giocatore non trovato.',
            description: 'Il profilo non è disponibile.',
            icon: Icons.person_off_outlined,
          ),
        );
      }

      final stats = state.stats!;
      final profile = state.profile;
      Widget section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: ProfileSectionHeading(title),
      );
      return ItaliaPage(
        title: 'PROFILO',
        showBack: true,
        mastheadKey: const ValueKey('profile-masthead'),
        footballKey: const ValueKey('profile-brand-football'),
        child: CustomScrollView(
          key: const ValueKey('profile-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Italia90.page,
                0,
                Italia90.page,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  ProfileIdentity(stats: stats),
                  const SizedBox(height: Italia90.page),
                  ProfileStatistics(
                    stats: stats,
                    results: profile.recentResults,
                  ),
                  section('INTESA E RIVALITÀ'),
                  ProfileRelationships(
                    profile: profile,
                    players: state.players,
                  ),
                  section('TESTA A TESTA'),
                  if (profile.headToHead.isNotEmpty)
                    const ColoredBox(
                      color: Italia90.panel,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('GIOCATORE', style: Italia90.caption),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                'PG',
                                textAlign: TextAlign.center,
                                style: Italia90.caption,
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                'V',
                                textAlign: TextAlign.center,
                                style: Italia90.caption,
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                'P',
                                textAlign: TextAlign.center,
                                style: Italia90.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (profile.headToHead.isEmpty)
                    const ProfilePanel(
                      child: Text('Nessun confronto diretto disponibile.'),
                    ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Italia90.page),
              sliver: SliverList.separated(
                itemCount: profile.headToHead.length,
                itemBuilder: (context, index) => ProfileHeadToHeadRow(
                  item: profile.headToHead[index],
                  players: state.players,
                ),
                separatorBuilder: (context, index) => const SizedBox.shrink(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Italia90.page),
              sliver: SliverToBoxAdapter(child: section('STORICO PERSONALE')),
            ),
            if (state.personalMatches.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: Italia90.page),
                sliver: SliverToBoxAdapter(
                  child: ProfilePanel(child: Text('Nessuna partita giocata.')),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Italia90.page),
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
                      const SizedBox(height: Italia90.md),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: Italia90.xxl + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      );
    },
  );
}
