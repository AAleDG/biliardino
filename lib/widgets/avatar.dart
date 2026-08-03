import 'package:flutter/material.dart';

Color hudColorForName(String name) {
  if (name.isEmpty) return const Color(0xFF28E0FF);

  final hash = name.toLowerCase().codeUnits.fold<int>(0, (value, codeUnit) {
    return ((value * 31) + codeUnit) & 0x7fffffff;
  });

  final hue = (hash % 360).toDouble();
  final saturation = 0.58 + ((hash >> 4) % 18) / 100;
  final lightness = 0.58 + ((hash >> 9) % 12) / 100;

  return HSLColor.fromAHSL(
    1,
    hue,
    saturation.clamp(0.55, 0.76),
    lightness.clamp(0.52, 0.68),
  ).toColor();
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
