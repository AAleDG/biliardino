import '../models/app_style.dart';
import 'app_presentation.dart';
import 'south_africa/south_africa_presentation.dart';
import 'italia90/italia90_presentation.dart';

/// Exhaustive over installed styles; no unavailable placeholder presentation.
AppPresentation presentationFor(AppStyle style) => switch (style) {
  AppStyle.southAfrica2010 => const SouthAfricaPresentation(),
  AppStyle.italia90 => const Italia90Presentation(),
};
