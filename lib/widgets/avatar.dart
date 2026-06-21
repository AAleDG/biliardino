import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    this.size = 36,
    this.fontSize,
  });

  final String name;
  final double size;
  final double? fontSize;

  Color _bgColor() {
    if (name.isEmpty) return NttColors.surfaceHigh;
    final hue = (name.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.45).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor(),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: fontSize ?? size * 0.42,
        ),
      ),
    );
  }
}
