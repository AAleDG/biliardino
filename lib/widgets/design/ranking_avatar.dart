import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// One shared ribbon identity for every ranking player, independent of teams.
class RankingAvatar extends StatelessWidget {
  const RankingAvatar({super.key, required this.name, this.size = 48});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: const _Ring(),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            textScaler: TextScaler.noScaling,
            style: AppType.section.copyWith(fontSize: size * .48),
          ),
        ),
      ),
    ),
  );
}

class _Ring extends CustomPainter {
  const _Ring();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = AppColors.surface);
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()..color = AppColors.background,
    );
    final rect = Rect.fromCircle(center: center, radius: radius - 4);
    const colors = [
      AppColors.yellow,
      AppColors.success,
      AppColors.yellow,
      AppColors.primary,
    ];
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * math.pi / 2,
        math.pi / 2,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Ring oldDelegate) => false;
}
