import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/italia90_motion.dart';

/// Approved revision 4 masters; their geometry is owned by assets/italia90.
class ItaliaFootball extends StatelessWidget {
  const ItaliaFootball({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/italia90/football-mark.svg',
      width: size,
      height: size,
    ),
  );
}

/// The home-only wordmark companion uses the football as the final visual
/// mark, matching the reference composition without rasterising the title.
class ItaliaHomeBrandMark extends StatelessWidget {
  const ItaliaHomeBrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/italia90/home-brand-mark.svg',
      width: size,
      height: size,
    ),
  );
}

class ItaliaCiao extends StatelessWidget {
  const ItaliaCiao({super.key, this.height = 170, this.animate = false});
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final artwork = ExcludeSemantics(
      child: SvgPicture.asset('assets/italia90/ciao.svg', height: height),
    );
    if (!animate || Italia90Motion.reducedOf(context)) return artwork;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Italia90Motion.splash,
      curve: Italia90Motion.curve,
      child: artwork,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
