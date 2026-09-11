import 'package:flutter/material.dart';

import '../../models/game_match.dart';
import '../../theme/app_theme.dart';
import '../../widgets/design/brand_choice_selector.dart';

class MatchSetupHeader extends StatelessWidget {
  const MatchSetupHeader({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
    child: Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            'NUOVA PARTITA',
            textAlign: TextAlign.center,
            style: AppType.screen.copyWith(fontSize: 36),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'SCEGLI I GIOCATORI E FORMA LE SQUADRE',
          textAlign: TextAlign.center,
          style: AppType.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: .7,
          ),
        ),
      ],
    ),
  );
}

class MatchModeSelector extends StatelessWidget {
  const MatchModeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  final MatchMode selectedMode;
  final ValueChanged<MatchMode>? onChanged;

  @override
  Widget build(BuildContext context) => BrandChoiceSelector<MatchMode>(
    selected: selectedMode,
    onChanged: onChanged,
    choices: [
      for (final mode in MatchMode.values)
        BrandChoice(
          value: mode,
          label: matchModeTitle(mode),
          semanticKey: ValueKey(
            'match-mode-${mode == MatchMode.oneVsOne ? 'one-vs-one' : 'two-vs-two'}',
          ),
          semanticLabel:
              '${matchModeTitle(mode)}: ${mode == MatchMode.oneVsOne ? '2 giocatori totali, uno per squadra.' : '4 giocatori totali, due per squadra.'}',
        ),
    ],
  );
}

String matchModeTitle(MatchMode mode) =>
    mode == MatchMode.oneVsOne ? '1 VS 1' : '2 VS 2';
