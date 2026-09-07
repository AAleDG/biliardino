import 'package:biliardino/screens/splash_screen.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/celebrations.dart';
import 'package:flutter/material.dart';

/// Development-only replay surface. Build this target into the isolated review
/// bundle described in the feature runbook; it never opens application storage.
void main() => runApp(const _Preview());

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.splash,
    value: 1,
  );
  CelebrationOverlayHandle? _goal, _victory;
  bool _reduced = false;
  @override
  void dispose() {
    _goal?.dismiss();
    _victory?.dismiss();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.southAfrica(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: _reduced),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('MOTION PREVIEW')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SwitchListTile(
              title: const Text('Riduci movimento'),
              value: _reduced,
              onChanged: (value) {
                setState(() => _reduced = value);
                if (value) {
                  _entrance.stop();
                  _entrance.value = 1;
                }
              },
            ),
            Center(
              child: AnimatedBuilder(
                animation: _entrance,
                builder: (_, _) =>
                    FootOriginEntrance(progress: _entrance.value),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (!_reduced) {
                  _entrance.forward(from: 0);
                }
              },
              child: const Text('RIPETI INGRESSO'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _goal?.dismiss();
                _goal = Celebrations.showGoal(
                  context,
                  color: AppColors.teamOne,
                  teamLabel: 'ANDREA · SQUADRA 1',
                );
              },
              child: const Text('GOAL'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _victory?.dismiss();
                _victory = Celebrations.showVictory(
                  context,
                  color: AppColors.teamTwo,
                  teamLabel: 'SQUADRA 2',
                  playerNames: const ['Marco', 'Paolo'],
                  winnerScore: 11,
                  loserScore: 9,
                  onChangeTeams: () {},
                  onRematch: () {},
                );
              },
              child: const Text('VITTORIA'),
            ),
          ],
        ),
      ),
    ),
  );
}
