import 'package:flutter/material.dart';

const List<Color> _hudPalette = [
  Color(0xFF28E0FF), // cyan
  Color(0xFFFF3D9A), // magenta
  Color(0xFF7CFC9F), // mint
  Color(0xFFFFD23F), // amber
  Color(0xFFB283FF), // violet
  Color(0xFFFF8C42), // orange
  Color(0xFF4DA8FF), // sky blue
  Color(0xFFFF5C73), // coral
  Color(0xFF5EEAD4), // teal
  Color(0xFFE879F9), // pink
];

Color hudColorForName(String name) {
  if (name.isEmpty) return _hudPalette.first;
  final sum = name.codeUnits.fold<int>(0, (a, b) => a + b);
  return _hudPalette[sum % _hudPalette.length];
}

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
    final accent = color ?? hudColorForName(name);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w500,
          fontSize: fontSize ?? size * 0.42,
        ),
      ),
    );
  }
}
