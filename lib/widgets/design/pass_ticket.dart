import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'pass_artwork.dart';

class PassTicketShape extends OutlinedBorder {
  const PassTicketShape({
    super.side = const BorderSide(color: AppColors.divider),
  });
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);
  @override
  PassTicketShape copyWith({BorderSide? side}) =>
      PassTicketShape(side: side ?? this.side);
  @override
  ShapeBorder scale(double t) => PassTicketShape(side: side.scale(t));
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final base = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.panel)),
      );
    final cuts = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(rect.left, rect.center.dy),
          radius: 10.5,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(rect.right, rect.center.dy),
          radius: 10.5,
        ),
      );
    return Path.combine(PathOperation.difference, base, cuts);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width));
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(getOuterPath(rect.deflate(side.width / 2)), side.toPaint());
  }
}

class PassTicket extends StatelessWidget {
  const PassTicket({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    this.format,
    this.onTap,
  });
  final String title, subtitle;
  final IconData icon, trailing;
  final String? format;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final color = onTap == null ? AppColors.disabledContent : AppColors.primary;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(title, style: AppType.screen.copyWith(fontSize: 32)),
            if (format != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: format == 'CSV'
                      ? AppColors.successContainer
                      : AppColors.teamOneContainer,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  format!,
                  style: AppType.caption.copyWith(
                    color: format == 'CSV'
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppType.body.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
    final leading = ExcludeSemantics(child: Icon(icon, size: 56, color: color));
    final ending = ExcludeSemantics(
      child: Icon(trailing, size: 30, color: color),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.ink.withValues(alpha: .14),
        shape: const PassTicketShape(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const PassTicketShape(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dividerX = constraints.maxWidth * .245;
              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    width: constraints.maxWidth * (190 / 430),
                    height: constraints.maxWidth * (57 / 430),
                    child: const IgnorePointer(
                      child: CustomPaint(
                        painter: PassRibbons(PassRibbonKind.corner),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: large ? 0 : constraints.maxWidth * (144 / 430),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: large
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [leading, ending],
                                ),
                                const SizedBox(height: 12),
                                content,
                              ],
                            )
                          : IntrinsicHeight(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: dividerX - 12,
                                    child: Center(child: leading),
                                  ),
                                  const SizedBox(
                                    width: 1,
                                    child: CustomPaint(
                                      painter: _Perforation(),
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: content),
                                  const SizedBox(width: 6),
                                  ending,
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Perforation extends CustomPainter {
  const _Perforation();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;
    for (double y = 0; y + 3 <= size.height; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Perforation oldDelegate) => false;
}
