import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared neutral identity outside a match; color must not imply team assignment.
Color avatarColorForName(String name) => AppColors.ink;

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    this.size = 36,
    this.fontSize,
    this.color,
  });
  final String name;
  final double size;
  final double? fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? avatarColorForName(name);
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Text(
          initial,
          textScaler: TextScaler.noScaling,
          style: AppType.section.copyWith(
            color: accent,
            fontSize: fontSize ?? size * .5,
          ),
        ),
      ),
    );
  }
}
