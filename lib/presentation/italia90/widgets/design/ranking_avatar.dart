import 'package:flutter/material.dart';

import '../avatar.dart';
import '../../theme/italia90_tokens.dart';

/// Returns a stable accent for a ranking identity across the podium and ledger.
///
/// Rank colours describe the podium positions, not the people in them. Using a
/// name-derived accent keeps the same player or pair recognisable when the
/// ranking is shown in more than one component.
Color rankingIdentityColor(String identity) {
  const palette = [
    Italia90.teamOne,
    Italia90.red,
    Italia90.green,
    Italia90.teamTwo,
  ];
  final hash = identity.toLowerCase().codeUnits.fold<int>(
    0,
    (value, codeUnit) => ((value * 31) + codeUnit) & 0x7fffffff,
  );
  return palette[hash % palette.length];
}

/// Ranking-specific name for the shared Italia avatar primitive.
class RankingAvatar extends StatelessWidget {
  const RankingAvatar({super.key, required this.name, this.size = 48});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) =>
      PlayerAvatar(name: name, size: size, color: rankingIdentityColor(name));
}
