import 'package:flutter/material.dart';

import '../../models/game_match.dart';
import '../../theme/app_theme.dart';

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
  Widget build(BuildContext context) => Container(
    height: (MediaQuery.textScalerOf(context).scale(28) * 1.1 + 8).clamp(
      58.0,
      double.infinity,
    ),
    padding: const EdgeInsets.all(1),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        for (final mode in MatchMode.values)
          Expanded(
            child: _ModeChoice(
              mode: mode,
              selected: mode == selectedMode,
              onTap: onChanged == null ? null : () => onChanged!(mode),
            ),
          ),
      ],
    ),
  );
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final MatchMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = matchModeTitle(mode);
    final description = mode == MatchMode.oneVsOne
        ? '2 giocatori totali, uno per squadra.'
        : '4 giocatori totali, due per squadra.';
    final color = selected ? AppColors.onPrimary : AppColors.ink;
    final radius = BorderRadius.horizontal(
      left: Radius.circular(mode == MatchMode.oneVsOne ? 28 : 16),
      right: Radius.circular(mode == MatchMode.oneVsOne ? 16 : 28),
    );
    return Semantics(
      key: ValueKey(
        'match-mode-${mode == MatchMode.oneVsOne ? 'one-vs-one' : 'two-vs-two'}',
      ),
      container: true,
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: '$title: $description',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Center(
              child: Text(
                title,
                style: AppType.action.copyWith(color: color, fontSize: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String matchModeTitle(MatchMode mode) =>
    mode == MatchMode.oneVsOne ? '1 VS 1' : '2 VS 2';
