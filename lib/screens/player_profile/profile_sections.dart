import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/game_match.dart';
import '../../models/player.dart';
import '../../models/player_profile_stats.dart';
import '../../models/ranking_stats.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';
import '../../widgets/design/adaptive_pair.dart';
import '../../widgets/design/profile_artwork.dart';

class ProfilePanel extends StatelessWidget {
  const ProfilePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.page),
    this.sweep = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final bool sweep;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.divider),
      borderRadius: BorderRadius.circular(AppRadius.panel),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        if (sweep)
          const Positioned(
            right: 0,
            bottom: 0,
            width: 92,
            height: 40,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: CustomPaint(painter: ProfileCornerSweep()),
              ),
            ),
          ),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

class ProfileSectionHeading extends StatelessWidget {
  const ProfileSectionHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Text(text, style: AppType.section));
}

class ProfileStatistics extends StatelessWidget {
  const ProfileStatistics({
    super.key,
    required this.stats,
    required this.results,
    this.heading = 'LE MIE STATISTICHE',
  });
  final RankingStats stats;
  final String heading;
  final List<bool> results;
  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Partite', '${stats.games}'),
      ('Vittorie', '${stats.wins}'),
      ('Sconfitte', '${stats.losses}'),
      ('Gol', '${stats.goalsScored}'),
      ('Win rate', '${(stats.winRate * 100).round()}%'),
      ('Serie', '${stats.currentWinStreak}'),
    ];
    return ProfilePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionHeading(heading),
          const SizedBox(height: AppSpace.page),
          LayoutBuilder(
            builder: (context, constraints) {
              final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final columns = large
                  ? (constraints.maxWidth >= 400 ? 2 : 1)
                  : (constraints.maxWidth >= 320 ? 3 : 2);
              final width =
                  (constraints.maxWidth - (columns - 1) * AppSpace.medium) /
                  columns;
              return Wrap(
                spacing: AppSpace.medium,
                runSpacing: AppSpace.page,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: width,
                      child: Semantics(
                        label: '${metric.$1}: ${metric.$2}',
                        excludeSemantics: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(metric.$2, style: AppType.screen),
                            Text(
                              metric.$1,
                              style: AppType.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.medium),
            child: Divider(height: 1),
          ),
          const ProfileSectionHeading('FORMA RECENTE'),
          const SizedBox(height: AppSpace.medium),
          if (results.isEmpty)
            const Text(
              'La forma comparirà dopo la prima partita.',
              style: AppType.body,
            )
          else
            Wrap(
              spacing: AppSpace.small,
              runSpacing: AppSpace.small,
              children: [
                for (final entry in results.asMap().entries)
                  Semantics(
                    key: ValueKey('profile-recent-result-${entry.key}'),
                    container: true,
                    label: entry.value ? 'Vittoria' : 'Sconfitta',
                    child: ExcludeSemantics(
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.medium,
                          vertical: AppSpace.small,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.value
                              ? AppColors.successContainer
                              : AppColors.disabledContainer,
                        ),
                        child: Text(
                          entry.value ? 'V' : 'P',
                          textAlign: TextAlign.center,
                          style: AppType.bodyStrong.copyWith(
                            color: entry.value
                                ? AppColors.successPressed
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class ProfileRelationships extends StatelessWidget {
  const ProfileRelationships({
    super.key,
    required this.profile,
    required this.players,
  });
  final PlayerProfileStats profile;
  final List<Player> players;
  @override
  Widget build(BuildContext context) {
    final teammate = profile.mostFrequentTeammate,
        opponent = profile.mostPlayedOpponent;
    if (teammate == null && opponent == null) {
      return const ProfilePanel(
        child: Text('Servono partite in squadra o contro altri giocatori.'),
      );
    }
    return AdaptivePair(
      first: _RelationshipCard(
        relationship: teammate,
        players: players,
        opponent: false,
      ),
      second: _RelationshipCard(
        relationship: opponent,
        players: players,
        opponent: true,
      ),
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  const _RelationshipCard({
    required this.relationship,
    required this.players,
    required this.opponent,
  });
  final PlayerFrequency? relationship;
  final List<Player> players;
  final bool opponent;
  @override
  Widget build(BuildContext context) {
    final names =
        relationship?.playerIds
            .map((id) => StatsService.playerName(players, id))
            .toList()
          ?..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final count = relationship?.matches;
    return ProfilePanel(
      sweep: true,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 34),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            opponent ? Icons.sports_martial_arts : Icons.group,
            color: opponent ? AppColors.error : AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent ? 'Avversario abituale' : 'Compagno abituale',
                  style: AppType.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpace.micro),
                Text(
                  names?.join(', ') ?? 'Non disponibile',
                  style: AppType.section.copyWith(fontSize: 20),
                ),
                if (count != null)
                  Text(
                    '$count ${count == 1 ? 'partita' : 'partite'}',
                    style: AppType.caption,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileHeadToHeadRow extends StatelessWidget {
  const ProfileHeadToHeadRow({
    super.key,
    required this.item,
    required this.players,
  });
  final HeadToHeadStats item;
  final List<Player> players;
  @override
  Widget build(BuildContext context) {
    final name = StatsService.playerName(players, item.opponentId);
    final metric = '${item.wins}V · ${item.losses}P';
    return _ResultRow(
      leading: PlayerAvatar(name: name, size: 36),
      title: name,
      subtitle: '${item.games} ${item.games == 1 ? 'partita' : 'partite'}',
      metric: metric,
    );
  }
}

class ProfileMatchRow extends StatelessWidget {
  const ProfileMatchRow({
    super.key,
    required this.match,
    required this.players,
    required this.playerId,
  });
  final GameMatch match;
  final List<Player> players;
  final String playerId;
  @override
  Widget build(BuildContext context) {
    final won = match.winners.contains(playerId);
    final opponents =
        (match.team1.contains(playerId) ? match.team2 : match.team1)
            .map((id) => StatsService.playerName(players, id))
            .join(' / ');
    return _ResultRow(
      leading: Icon(
        won ? Icons.emoji_events : Icons.close,
        color: won ? AppColors.success : AppColors.textSecondary,
      ),
      title:
          '${won ? 'Vittoria' : 'Sconfitta'} · ${match.t1Score}-${match.t2Score}',
      subtitle:
          '${DateFormat('dd/MM/yyyy HH:mm').format(match.playedAt)} · vs $opponents',
      metric: '${match.goalsByPlayer(playerId)} gol',
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.metric,
  });
  final Widget leading;
  final String title, subtitle, metric;
  @override
  Widget build(BuildContext context) => ProfilePanel(
    padding: const EdgeInsets.all(AppSpace.medium),
    child: LayoutBuilder(
      builder: (context, constraints) {
        var stacked =
            constraints.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        if (!stacked) {
          final metrics = TextPainter(
            text: TextSpan(text: metric, style: AppType.section),
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: Directionality.of(context),
          )..layout();
          stacked = metrics.width > constraints.maxWidth * .4;
          metrics.dispose();
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: leading),
            const SizedBox(width: AppSpace.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.bodyStrong),
                  const SizedBox(height: AppSpace.micro),
                  Text(
                    subtitle,
                    style: AppType.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (stacked)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.small),
                      child: Text(metric, style: AppType.section),
                    ),
                ],
              ),
            ),
            if (!stacked) ...[
              const SizedBox(width: AppSpace.medium),
              Text(metric, style: AppType.section),
            ],
          ],
        );
      },
    ),
  );
}
