import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../avatar.dart';

/// Shared player treatment in setup cards and live score panels.
class TeamSlot extends StatelessWidget {
  const TeamSlot({super.key, required this.name, required this.teamColor});
  final String name;
  final Color teamColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.teamContainer(teamColor),
      borderRadius: BorderRadius.circular(AppRadius.small),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          PlayerAvatar(name: name, size: 32),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: AppType.bodyStrong)),
        ],
      ),
    ),
  );
}
