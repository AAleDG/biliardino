import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/player.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar.dart';

Future<String?> chooseReplacement(
  BuildContext context,
  List<Player> candidates,
) async {
  if (candidates.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nessun altro giocatore disponibile.')),
    );
    return null;
  }
  if (candidates.length == 1) return candidates.single.id;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _Roster(candidates),
  );
}

class _Roster extends StatefulWidget {
  const _Roster(this.players);
  final List<Player> players;
  @override
  State<_Roster> createState() => _RosterState();
}

class _RosterState extends State<_Roster> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final matches = widget.players
        .where(
          (p) => Player.normalizedNameKey(
            p.name,
          ).contains(Player.normalizedNameKey(query)),
        )
        .toList();
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('SCEGLI GIOCATORE', style: AppType.section),
                      ),
                      IconButton(
                        tooltip: 'Annulla scelta giocatore',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    key: const ValueKey('edit-roster-search'),
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cerca giocatore',
                    ),
                  ),
                ),
              ),
              if (matches.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(child: Text('Nessun giocatore trovato')),
                )
              else
                SliverList.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final p = matches[index];
                    return ListTile(
                      key: ValueKey('edit-pick-${p.id}'),
                      leading: PlayerAvatar(
                        name: p.name,
                        color: AppColors.primary,
                      ),
                      title: Text(p.name),
                      subtitle: p.isArchived ? const Text('Archiviato') : null,
                      onTap: () => Navigator.pop(context, p.id),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<int?> chooseScore(BuildContext context, int team, int value) =>
    showDialog<int>(
      context: context,
      builder: (_) => _ScoreInput(team: team, value: value),
    );

class _ScoreInput extends StatefulWidget {
  const _ScoreInput({required this.team, required this.value});
  final int team, value;
  @override
  State<_ScoreInput> createState() => _ScoreInputState();
}

class _ScoreInputState extends State<_ScoreInput> {
  late final controller = TextEditingController(text: '${widget.value}');
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final value = int.tryParse(controller.text);
    if (value == null || value < 0) {
      setState(() => error = 'Inserisci un punteggio valido.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text('Punteggio squadra ${widget.team}'),
    content: TextField(
      key: const ValueKey('edit-score-input'),
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSubmitted: (_) => submit(),
      decoration: InputDecoration(labelText: 'Gol', errorText: error),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      TextButton(onPressed: submit, child: const Text('Conferma')),
    ],
  );
}
