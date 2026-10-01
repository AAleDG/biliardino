import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/celebrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Replays the production overlay with sample data, without opening storage.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.southAfrica(),
      home: const _VictoryPreview(),
    ),
  );
}

class _VictoryPreview extends StatefulWidget {
  const _VictoryPreview();

  @override
  State<_VictoryPreview> createState() => _VictoryPreviewState();
}

class _VictoryPreviewState extends State<_VictoryPreview> {
  CelebrationOverlayHandle? _overlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _show(1);
    });
  }

  void _show(int team) {
    _overlay?.dismiss();
    _overlay = Celebrations.showVictory(
      context,
      color: team == 1 ? AppColors.teamOne : AppColors.teamTwo,
      teamLabel: 'SQUADRA $team',
      playerNames: team == 1 ? const ['Andrea'] : const ['Marco', 'Paolo'],
      winnerScore: 10,
      loserScore: team == 1 ? 1 : 8,
      onChangeTeams: () => _overlay = null,
      onRematch: () => _overlay = null,
    );
  }

  @override
  void dispose() {
    _overlay?.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ANTEPRIMA VITTORIA')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Solo anteprima. Nessuna partita viene registrata.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _show(1),
              child: const Text('RIPETI · SQUADRA 1'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _show(2),
              child: const Text('RIPETI · SQUADRA 2'),
            ),
          ],
        ),
      ),
    ),
  );
}
