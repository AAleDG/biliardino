import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final players = state.players;
    final presentCount = players.where((p) => p.isPresent).length;

    return Scaffold(
      appBar: AppBar(title: const Text('GIOCATORI')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('NUOVO'),
      ),
      body: players.isEmpty
          ? const _Empty()
          : Column(
              children: [
                _summary(presentCount, players.length),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                    itemCount: players.length,
                    itemBuilder: (_, i) => _PlayerRow(
                      player: players[i],
                      onToggle: () => state.togglePresent(players[i]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summary(int presentCount, int total) {
    final ready = presentCount >= 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Pill(
            text: '$presentCount/$total presenti',
            color: NttColors.accent,
          ),
          _Pill(
            text: ready
                ? 'Pronti a giocare'
                : 'Servono ${4 - presentCount} per giocare',
            color: ready ? NttColors.success : NttColors.textFaint,
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    void submit(BuildContext ctx) {
      final name = controller.text.trim();
      if (name.isNotEmpty) {
        context.read<AppState>().addPlayer(name);
        Navigator.pop(ctx);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuovo giocatore'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
          onSubmitted: (_) => submit(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => submit(ctx),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.onToggle});

  final Player player;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              PlayerAvatar(name: player.name, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _PresenceBadge(
                        key: ValueKey(player.isPresent),
                        isPresent: player.isPresent,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: player.isPresent, onChanged: (_) => onToggle()),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresenceBadge extends StatelessWidget {
  const _PresenceBadge({super.key, required this.isPresent});

  final bool isPresent;

  @override
  Widget build(BuildContext context) {
    final color = isPresent ? NttColors.success : NttColors.textFaint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow:
                isPresent ? [BoxShadow(color: color, blurRadius: 6)] : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isPresent ? 'In ufficio' : 'Assente',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.people_outline, size: 64, color: NttColors.textFaint),
              SizedBox(height: 16),
              Text(
                'Nessun giocatore',
                style: TextStyle(
                  color: NttColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Aggiungi il primo player con il pulsante in basso.',
                textAlign: TextAlign.center,
                style: TextStyle(color: NttColors.textMuted),
              ),
            ],
          ),
        ),
      );
}
