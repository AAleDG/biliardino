import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Provides the artwork handle used by profile surfaces.
///
/// The Africa implementation loads a raster scene before handing it to its
/// painters. Italia '90 keeps the same builder boundary and lifecycle seam,
/// while its approved profile artwork is vector-only and therefore does not
/// need an additional runtime image asset.
class FoosballScene extends StatelessWidget {
  const FoosballScene({super.key, required this.builder});

  final Widget Function(BuildContext context, ui.Image? scene) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
