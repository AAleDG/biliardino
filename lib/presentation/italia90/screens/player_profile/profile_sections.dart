import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/game_match.dart';
import '../../../../models/player.dart';
import '../../../../models/player_profile_stats.dart';
import '../../../../models/player_stats.dart';
import '../../../../services/stats_service.dart';
import '../../theme/italia90_tokens.dart';

/// Flat white ruled surface shared by profile sections and records.
class ProfilePanel extends StatelessWidget {
  const ProfilePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Italia90.page),
    this.sweep = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool sweep;

  @override
  Widget build(BuildContext context) => Material(
    color: Italia90.panel,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Italia90.subtle),
          bottom: BorderSide(color: Italia90.subtle),
        ),
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class ProfileSectionHeading extends StatelessWidget {
  const ProfileSectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: Italia90.heading.copyWith(fontSize: 21)),
  );
}

class ProfileStatistics extends StatelessWidget {
  const ProfileStatistics({
    super.key,
    required this.stats,
    required this.results,
  });

  final PlayerStats stats;
  final List<bool> results;

  @override
  Widget build(BuildContext context) {
    final metrics = <({String label, String value})>[
      (label: 'Partite', value: '${stats.games}'),
      (label: 'Vittorie', value: '${stats.wins}'),
      (label: 'Sconfitte', value: '${stats.losses}'),
      (label: 'Gol', value: '${stats.goalsScored}'),
      (label: 'Win rate', value: '${(stats.winRate * 100).round()}%'),
      (label: 'Serie', value: '${stats.currentWinStreak}'),
    ];

    final markerSize = MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? 42.0
        : 29.0;
    final fixedResults = List<bool?>.generate(
      5,
      (index) => index < results.length ? results[index] : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionHeading('LE MIE STATISTICHE'),
        const SizedBox(height: 10),
        ProfilePanel(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? (constraints.maxWidth >= 400 ? 2 : 1)
                  : (constraints.maxWidth >= 320 ? 3 : 2);
              final width = constraints.maxWidth / columns;
              return Wrap(
                children: [
                  for (final entry in metrics.asMap().entries)
                    SizedBox(
                      width: width,
                      child: Container(
                        key: ValueKey('profile-metric-${entry.key}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            right: (entry.key + 1) % columns == 0
                                ? BorderSide.none
                                : const BorderSide(color: Italia90.subtle),
                            bottom: entry.key < metrics.length - columns
                                ? const BorderSide(color: Italia90.subtle)
                                : BorderSide.none,
                          ),
                        ),
                        child: Semantics(
                          label: '${entry.value.label}: ${entry.value.value}',
                          excludeSemantics: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value.value,
                                style: Italia90.display.copyWith(
                                  fontSize: 32,
                                  color: entry.value.label == 'Win rate'
                                      ? Italia90.success
                                      : Italia90.ink,
                                ),
                              ),
                              Text(
                                entry.value.label,
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
        ProfilePanel(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final markers = Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final entry in fixedResults.asMap().entries)
                    Semantics(
                      key: ValueKey('profile-recent-result-${entry.key}'),
                      container: true,
                      label: switch (entry.value) {
                        true => 'Vittoria',
                        false => 'Sconfitta',
                        null => 'Risultato non disponibile',
                      },
                      child: ExcludeSemantics(
                        child: Container(
                          width: markerSize,
                          height: markerSize,
                          alignment: Alignment.center,
                          color: switch (entry.value) {
                            true => const Color(0xFFE1F1E9),
                            false => Italia90.subtle,
                            null => Italia90.surface,
                          },
                          child: Text(
                            switch (entry.value) {
                              true => 'V',
                              false => 'P',
                              null => '—',
                            },
                            style: Italia90.label.copyWith(
                              fontSize: 14,
                              color: entry.value == true
                                  ? Italia90.success
                                  : Italia90.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
              final horizontal =
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3 &&
                  constraints.maxWidth >= 300;
              final label = Semantics(
                header: true,
                child: Text(
                  'FORMA RECENTE',
                  style: Italia90.label.copyWith(fontSize: 14),
                ),
              );
              if (horizontal) {
                return Row(
                  children: [
                    Expanded(child: label),
                    const SizedBox(width: 10),
                    markers,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label,
                  const SizedBox(height: 8),
                  markers,
                  if (results.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'La forma comparirà dopo la prima partita.',
                      style: Italia90.body,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
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
    final teammate = profile.mostFrequentTeammate;
    final opponent = profile.mostPlayedOpponent;
    if (teammate == null && opponent == null) {
      return const ProfilePanel(
        child: Text('Servono partite in squadra o contro altri giocatori.'),
      );
    }
    final first = _RelationshipCard(
      relationship: teammate,
      players: players,
      opponent: false,
    );
    final second = _RelationshipCard(
      relationship: opponent,
      players: players,
      opponent: true,
    );
    return ProfilePanel(
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [first, const SizedBox(height: 12), second],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          );
        },
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
    final matches = relationship?.matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              opponent ? Icons.sports_martial_arts : Icons.group,
              color: opponent ? Italia90.error : Italia90.primary,
              size: 17,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                opponent ? 'Avversario abituale' : 'Compagno abituale',
                style: Italia90.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          names?.join(', ') ?? 'Non disponibile',
          style: Italia90.title.copyWith(fontSize: 18),
        ),
        if (matches != null)
          Text(
            '$matches ${matches == 1 ? 'partita' : 'partite'}',
            style: Italia90.caption,
          ),
      ],
    );
  }
}

class ProfileHeadToHead extends StatelessWidget {
  const ProfileHeadToHead({
    super.key,
    required this.profile,
    required this.players,
  });

  final PlayerProfileStats profile;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    if (profile.headToHead.isEmpty) {
      return const ProfilePanel(
        child: Text('Nessun confronto diretto disponibile.'),
      );
    }
    return ProfilePanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < profile.headToHead.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ProfileHeadToHeadRow(item: profile.headToHead[i], players: players),
          ],
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
    return Semantics(
      label:
          '$name. ${item.games} partite, ${item.wins} vittorie, ${item.losses} sconfitte.',
      excludeSemantics: true,
      child: ProfilePanel(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Text(name, style: Italia90.label.copyWith(fontSize: 14)),
            ),
            for (final metric in [
              (value: item.games, wins: false),
              (value: item.wins, wins: true),
              (value: item.losses, wins: false),
            ])
              SizedBox(
                width: 36,
                child: Text(
                  '${metric.value}',
                  textAlign: TextAlign.center,
                  style: Italia90.body.copyWith(
                    fontSize: 14,
                    fontWeight: metric.wins ? FontWeight.w700 : FontWeight.w400,
                    color: metric.wins ? Italia90.success : Italia90.ink,
                  ),
                ),
              ),
          ],
        ),
      ),
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
    final opponentIds = match.team1.contains(playerId)
        ? match.team2
        : match.team1;
    final opponents = opponentIds
        .map((id) => StatsService.playerName(players, id))
        .join(' / ');
    final firstSide = match.team1.contains(playerId);
    final ownTeam = (firstSide ? match.team1 : match.team2)
        .map((id) => StatsService.playerName(players, id))
        .join(' + ');
    final score =
        '${firstSide ? match.t1Score : match.t2Score}-${firstSide ? match.t2Score : match.t1Score}';
    return ProfilePanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(match.playedAt),
                style: Italia90.caption,
              ),
              Text(
                won ? 'Vittoria' : 'Sconfitta',
                style: Italia90.label.copyWith(
                  fontSize: 12,
                  color: won ? Italia90.success : Italia90.primary,
                ),
              ),
              Text(
                '${match.goalsByPlayer(playerId)} gol',
                style: Italia90.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  ownTeam,
                  style: Italia90.label.copyWith(fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  opponents,
                  textAlign: TextAlign.right,
                  style: Italia90.label.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
