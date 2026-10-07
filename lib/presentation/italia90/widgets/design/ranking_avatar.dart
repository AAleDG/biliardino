import 'package:flutter/material.dart';

import '../avatar.dart';

/// Ranking-specific name for the shared Italia avatar primitive.
class RankingAvatar extends StatelessWidget {
  const RankingAvatar({super.key, required this.name, this.size = 48});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => PlayerAvatar(name: name, size: size);
}
