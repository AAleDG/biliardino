import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/pair_profile/pair_profile_cubit.dart';
import '../../../cubits/pair_profile/pair_profile_state.dart';
import '../../../models/game_match.dart';
import '../../../models/pair_profile_stats.dart';
import '../../../models/player.dart';
import '../../../repositories/match_repository.dart';
import '../../../repositories/player_repository.dart';
import '../../../services/stats_service.dart';
import '../theme/italia90_tokens.dart';
import '../widgets/avatar.dart';
import '../widgets/italia90_page.dart';
import '../widgets/ranking_recognitions.dart';
import '../../../navigation/app_navigation.dart';

class PairProfileScreen extends StatelessWidget {
  const PairProfileScreen({super.key, required this.pairId});

  final String pairId;

  @override
  Widget build(BuildContext context) => BlocProvider<PairProfileCubit>(
    key: ValueKey(pairId),
    create: (context) => PairProfileCubit(
      pairId: pairId,
      playerRepository: context.read<PlayerRepository>(),
      matchRepository: context.read<MatchRepository>(),
    ),
    child: const _PairProfileView(),
  );
}

class _PairProfileView extends StatelessWidget {
  const _PairProfileView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PairProfileCubit, PairProfileState>(
        builder: (context, state) {
          final profile = state.profile;
          return ItaliaPage(
            title: 'PROFILO COPPIA',
            titleStyle: Italia90.display.copyWith(fontSize: 36),
            showBack: true,
            mastheadKey: const ValueKey('pair-profile-masthead'),
            footballKey: const ValueKey('pair-profile-brand-football'),
            child: profile == null
                ? const ItaliaEmptyState(
                    title: 'Coppia non disponibile',
                    description:
                        'Nessuna partita insieme o giocatori non disponibili.',
                    icon: Icons.people_outline,
                  )
                : _PairProfileContent(profile: profile, players: state.players),
          );
        },
      );
}

class _PairProfileContent extends StatelessWidget {
  const _PairProfileContent({required this.profile, required this.players});

  final PairProfileStats profile;
  final List<Player> players;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const ValueKey('pair-profile-scroll'),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Italia90.page),
        sliver: SliverList.list(
          children: [
            _PairIdentity(profile: profile),
            RankingRecognitions(
              key: const ValueKey('pair-profile-recognitions'),
              keyPrefix: 'pair-profile',
              items: [
                for (final badge in profile.stats.badges)
                  RankingRecognition(
                    ownerId: profile.stats.id,
                    ownerName: profile.stats.name,
                    badge: badge,
                  ),
              ],
            ),
            const _SectionTitle('NUMERI DI COPPIA'),
            _PairMetrics(profile: profile),
            const _SectionTitle('AVVERSARI'),
            if (profile.opponents.isEmpty)
              const Text('Nessun confronto disponibile.', style: Italia90.body)
            else
              _PairOpponents(opponents: profile.opponents, players: players),
            const _SectionTitle('PARTITE INSIEME'),
            Text(
              '${profile.stats.games} partite',
              style: Italia90.body.copyWith(color: Italia90.muted),
            ),
          ],
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          Italia90.page,
          8,
          Italia90.page,
          Italia90.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        sliver: SliverList.separated(
          itemCount: profile.matches.length,
          itemBuilder: (context, index) => _PairMatchRow(
            key: ValueKey('pair-profile-match-${profile.matches[index].id}'),
            match: profile.matches[index],
            profile: profile,
            players: players,
          ),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
        ),
      ),
    ],
  );
}

class _PairIdentity extends StatelessWidget {
  const _PairIdentity({required this.profile});

  final PairProfileStats profile;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 138,
                height: 74,
                child: Stack(
                  children: [
                    for (
                      var index = 0;
                      index < profile.stats.players.length;
                      index++
                    )
                      Positioned(
                        left: index * 64,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Italia90.panel,
                            shape: BoxShape.circle,
                          ),
                          child: PlayerAvatar(
                            name: profile.stats.players[index].name,
                            size: 68,
                            color: index == 0 ? Italia90.teamOne : Italia90.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Semantics(
              label: 'Posizione ${profile.rank} in classifica generale',
              excludeSemantics: true,
              child: Column(
                children: [
                  Text(
                    '${profile.rank}',
                    style: Italia90.display.copyWith(
                      fontSize: 52,
                      color: Italia90.teamOne,
                    ),
                  ),
                  const Text('IN CLASSIFICA', style: Italia90.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          profile.stats.name,
          key: const ValueKey('pair-profile-name'),
          textAlign: TextAlign.center,
          style: Italia90.title.copyWith(fontSize: 29),
        ),
        const SizedBox(height: 6),
        Text(
          'Insieme dal ${DateFormat('d MMMM yyyy', 'it').format(profile.togetherSince)} · 2vs2',
          textAlign: TextAlign.center,
          style: Italia90.body.copyWith(fontSize: 13, color: Italia90.muted),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (
              var index = 0;
              index < profile.stats.players.length;
              index++
            ) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  key: ValueKey(
                    'pair-profile-player-${profile.stats.players[index].id}',
                  ),
                  onPressed: () => openPlayerProfile(
                    context,
                    profile.stats.players[index].id,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(profile.stats.players[index].name)),
                      const SizedBox(width: 6),
                      const Icon(Icons.north_east, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Semantics(
      header: true,
      child: Text(title, style: Italia90.heading.copyWith(fontSize: 21)),
    ),
  );
}

class _PairMetrics extends StatelessWidget {
  const _PairMetrics({required this.profile});

  final PairProfileStats profile;

  @override
  Widget build(BuildContext context) {
    final stats = profile.stats;
    final metrics = [
      (label: 'Partite', value: '${stats.games}'),
      (label: 'Punti', value: '${stats.points}'),
      (label: 'Vittorie', value: '${stats.wins}'),
      (label: 'Sconfitte', value: '${stats.losses}'),
      (label: 'Gol segnati', value: '${stats.goalsScored}'),
      (
        label: 'Percentuale vittorie',
        value: '${(stats.winRate * 100).round()}%',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: Italia90.panel,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? 1
                  : 2;
              return Wrap(
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: constraints.maxWidth / columns,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Italia90.subtle),
                          ),
                        ),
                        child: Semantics(
                          label: '${metric.label}: ${metric.value}',
                          excludeSemantics: true,
                          child: Column(
                            children: [
                              Text(
                                metric.value,
                                style: Italia90.display.copyWith(
                                  fontSize: 34,
                                  color: metric.label == 'Punti'
                                      ? Italia90.teamOne
                                      : Italia90.ink,
                                ),
                              ),
                              Text(
                                metric.label,
                                textAlign: TextAlign.center,
                                style: Italia90.body.copyWith(
                                  fontSize: 13,
                                  color: Italia90.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        const Text('Ultime 5 partite', style: Italia90.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final result in profile.recentResults)
              Semantics(
                label: result ? 'Vittoria' : 'Sconfitta',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  color: result ? Italia90.subtle : Italia90.brickContainer,
                  child: Text(
                    result ? 'V' : 'S',
                    style: Italia90.label.copyWith(
                      color: result ? Italia90.success : Italia90.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Serie positiva: ${stats.currentWinStreak} vittorie consecutive',
          style: Italia90.body.copyWith(fontSize: 14, color: Italia90.success),
        ),
      ],
    );
  }
}

class _PairOpponents extends StatelessWidget {
  const _PairOpponents({required this.opponents, required this.players});

  final List<PairOpponentStats> opponents;
  final List<Player> players;

  @override
  Widget build(BuildContext context) => Material(
    color: Italia90.panel,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(child: Text('COPPIA', style: Italia90.caption)),
              SizedBox(
                width: 36,
                child: Text('PG', textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 36,
                child: Text('V', textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 36,
                child: Text('S', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        for (final opponent in opponents)
          Builder(
            builder: (context) {
              final name = opponent.playerIds
                  .map((id) => StatsService.playerName(players, id))
                  .join(' + ');
              final available = opponent.playerIds.every(
                (id) => players.any((player) => player.id == id),
              );
              void open() => openPairProfile(context, opponent.id);
              return Semantics(
                key: ValueKey('pair-profile-opponent-${opponent.id}'),
                label:
                    '$name. ${opponent.games} partite, ${opponent.wins} vittorie, ${opponent.losses} sconfitte della coppia.',
                button: available,
                onTap: available ? open : null,
                excludeSemantics: true,
                child: InkWell(
                  onTap: available ? open : null,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Italia90.subtle)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: Italia90.label.copyWith(fontSize: 14),
                          ),
                        ),
                        for (final value in [
                          opponent.games,
                          opponent.wins,
                          opponent.losses,
                        ])
                          SizedBox(
                            width: 36,
                            child: Text(
                              '$value',
                              textAlign: TextAlign.center,
                              style: Italia90.body,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}

class _PairMatchRow extends StatelessWidget {
  const _PairMatchRow({
    super.key,
    required this.match,
    required this.profile,
    required this.players,
  });

  final GameMatch match;
  final PairProfileStats profile;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final firstSide = match.team1.toSet().containsAll(
      profile.stats.players.map((player) => player.id),
    );
    final won = match.winningTeam == (firstSide ? 1 : 2);
    final opponent = (firstSide ? match.team2 : match.team1)
        .map((id) => StatsService.playerName(players, id))
        .join(' + ');
    final score =
        '${firstSide ? match.t1Score : match.t2Score}-${firstSide ? match.t2Score : match.t1Score}';
    return Semantics(
      label:
          '${DateFormat('d MMMM yyyy HH:mm', 'it').format(match.playedAt)}. '
          '${profile.stats.name} contro $opponent. $score. ${won ? 'Vittoria' : 'Sconfitta'}.',
      excludeSemantics: true,
      child: Container(
        color: Italia90.panel,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  DateFormat('d MMM yyyy · HH:mm', 'it').format(match.playedAt),
                  style: Italia90.caption.copyWith(color: Italia90.muted),
                ),
                Text(
                  won ? 'VITTORIA' : 'SCONFITTA',
                  style: Italia90.label.copyWith(
                    fontSize: 12,
                    color: won ? Italia90.success : Italia90.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.stats.name,
                    style: Italia90.label.copyWith(fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    score,
                    style: Italia90.display.copyWith(
                      fontSize: 24,
                      color: Italia90.teamOne,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    opponent,
                    textAlign: TextAlign.right,
                    style: Italia90.label.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
