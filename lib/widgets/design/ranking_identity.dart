import 'package:flutter/material.dart';
import 'ranking_avatar.dart';

/// Reuses the approved ranking rings for individual and pair identities.
class RankingIdentity extends StatelessWidget {
  const RankingIdentity({super.key, required this.names, required this.size});
  final List<String> names;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (names.length == 1) return RankingAvatar(name: names.single, size: size);
    return SizedBox(
      height: size * .72,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final name in names) RankingAvatar(name: name, size: size * .72),
        ],
      ),
    );
  }
}
