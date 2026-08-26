import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../models/game_match.dart';
import '../models/player.dart';
import '../models/player_stats.dart';
import '../models/player_profile_stats.dart';
import '../repositories/match_repository.dart';
import '../repositories/player_repository.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key, required this.playerId});

  final String playerId;

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  late final PlayerRepository _playerRepository;
  late final MatchRepository _matchRepository;
  late final StreamSubscription<List<Player>> _playersSub;
  late final StreamSubscription<List<GameMatch>> _matchesSub;

  List<Player> _players = const [];
  List<GameMatch> _matches = const [];

  @override
  void initState() {
    super.initState();
    _playerRepository = context.read<PlayerRepository>();
    _matchRepository = context.read<MatchRepository>();
    _players = _playerRepository.players;
    _matches = _matchRepository.matches;
    _playersSub = _playerRepository.watchPlayers().listen((players) {
      if (mounted) {
        setState(() => _players = players);
      }
    });
    _matchesSub = _matchRepository.watchMatches().listen((matches) {
      if (mounted) {
        setState(() => _matches = matches);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_playersSub.cancel());
    unawaited(_matchesSub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _findPlayer(_players, widget.playerId);
    if (player == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PROFILO')),
        body: const Center(child: Text('Giocatore non trovato.')),
      );
    }

    final stats = StatsService.computeLeaderboard(
      _players,
      _matches,
    ).firstWhere((item) => item.player.id == player.id);
    final personalMatches = StatsService.matchesForPlayer(_matches, player.id);
    final profile = StatsService.computePlayerProfile(_matches, player.id);

    return Scaffold(
      appBar: AppBar(title: const Text('PROFILO')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Header(player: player, stats: stats),
          const SizedBox(height: 16),
          _StatsGrid(stats: stats),
          const SizedBox(height: 18),
          const _SectionLabel('FORMA RECENTE'),
          const SizedBox(height: 8),
          _RecentForm(results: profile.recentResults),
          const SizedBox(height: 18),
          const _SectionLabel('INTESA E RIVALITÀ'),
          const SizedBox(height: 8),
          _Relationships(profile: profile, players: _players),
          const SizedBox(height: 18),
          const _SectionLabel('TESTA A TESTA'),
          const SizedBox(height: 8),
          _HeadToHead(profile: profile, players: _players),
          const SizedBox(height: 18),
          const _SectionLabel('STORICO PERSONALE'),
          const SizedBox(height: 8),
          if (personalMatches.isEmpty)
            const _EmptyHistory()
          else
            ...personalMatches.map(
              (match) => _PersonalMatchRow(
                match: match,
                players: _players,
                playerId: player.id,
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentForm extends StatelessWidget {
  const _RecentForm({required this.results});

  final List<bool> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const _EmptyCard('La forma comparirà dopo la prima partita.');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            for (final won in results) ...[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (won ? NttColors.success : NttColors.textMuted)
                      .withValues(alpha: 0.18),
                ),
                child: Text(
                  won ? 'V' : 'P',
                  style: TextStyle(
                    color: won ? NttColors.success : NttColors.textMuted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Relationships extends StatelessWidget {
  const _Relationships({required this.profile, required this.players});

  final PlayerProfileStats profile;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final teammate = profile.mostFrequentTeammate;
    final opponent = profile.mostPlayedOpponent;
    if (teammate == null && opponent == null) {
      return const _EmptyCard(
        'Servono partite in squadra o contro altri giocatori.',
      );
    }
    return Row(
      children: [
        Expanded(
          child: _RelationshipCard(
            icon: Icons.group,
            label: 'Compagno abituale',
            value: teammate == null
                ? 'Non disponibile'
                : StatsService.playerName(players, teammate.playerId),
            matches: teammate?.matches,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RelationshipCard(
            icon: Icons.sports_martial_arts,
            label: 'Avversario abituale',
            value: opponent == null
                ? 'Non disponibile'
                : StatsService.playerName(players, opponent.playerId),
            matches: opponent?.matches,
          ),
        ),
      ],
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  const _RelationshipCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.matches,
  });

  final IconData icon;
  final String label;
  final String value;
  final int? matches;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: NttColors.accent, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: NttColors.textFaint)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (matches != null)
              Text('$matches partite', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _HeadToHead extends StatelessWidget {
  const _HeadToHead({required this.profile, required this.players});

  final PlayerProfileStats profile;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    if (profile.headToHead.isEmpty) {
      return const _EmptyCard('Nessun confronto diretto disponibile.');
    }
    return Card(
      child: Column(
        children: profile.headToHead.map((item) {
          final name = StatsService.playerName(players, item.opponentId);
          return ListTile(
            leading: PlayerAvatar(name: name, size: 36),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${item.games} partite'),
            trailing: Text(
              '${item.wins}V · ${item.losses}P',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(color: NttColors.textMuted),
        ),
      ),
    );
  }
}

Player? _findPlayer(List<Player> players, String playerId) {
  for (final player in players) {
    if (player.id == playerId) {
      return player;
    }
  }
  return null;
}

class _Header extends StatelessWidget {
  const _Header({required this.player, required this.stats});

  final Player player;
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            PlayerAvatar(name: player.name, size: 58),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NttColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    player.isPresent ? 'In ufficio' : 'Assente',
                    style: TextStyle(
                      color: player.isPresent
                          ? NttColors.success
                          : NttColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${stats.points} pt',
              style: const TextStyle(
                color: NttColors.accent,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _Metric(label: 'Partite', value: '${stats.games}'),
        _Metric(label: 'Vittorie', value: '${stats.wins}'),
        _Metric(label: 'Sconfitte', value: '${stats.losses}'),
        _Metric(label: 'Gol', value: '${stats.goalsScored}'),
        _Metric(label: 'Win rate', value: '${(stats.winRate * 100).round()}%'),
        _Metric(label: 'Serie', value: '${stats.currentWinStreak}'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NttColors.surfaceMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: NttColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: NttColors.textFaint,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalMatchRow extends StatelessWidget {
  const _PersonalMatchRow({
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
    final teamLabel = match.winners.contains(playerId)
        ? 'Vittoria'
        : 'Sconfitta';
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(match.playedAt);
    final opponentIds = match.team1.contains(playerId)
        ? match.team2
        : match.team1;
    final opponents = opponentIds
        .map((id) => StatsService.playerName(players, id))
        .join(' / ');
    return Card(
      child: ListTile(
        leading: Icon(
          won ? Icons.emoji_events : Icons.close,
          color: won ? NttColors.success : NttColors.textMuted,
        ),
        title: Text(
          '$teamLabel · ${match.t1Score}-${match.t2Score}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('$dateLabel · vs $opponents'),
        trailing: Text('${match.goalsByPlayer(playerId)} gol'),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: NttColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(child: Text('Nessuna partita giocata.')),
    );
  }
}
