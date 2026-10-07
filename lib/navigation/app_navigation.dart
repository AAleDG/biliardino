import 'package:flutter/material.dart';

import '../presentation/app_presentation.dart';
import '../screens/appearance_screen.dart';

Future<void> openHistory(BuildContext context) {
  return AppPresentationScope.of(context).openHistory(context);
}

Future<void> openDataManagement(BuildContext context) {
  return AppPresentationScope.of(context).openData(context);
}

Future<void> openPlayerProfile(BuildContext context, String playerId) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PresentationBuilder(
        builder: (presentation) => presentation.profile(playerId),
      ),
    ),
  );
}

Future<void> openPairProfile(BuildContext context, String pairId) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PresentationBuilder(
        builder: (presentation) => presentation.pairProfile(pairId),
      ),
    ),
  );
}

Future<void> openAppearance(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const AppearanceScreen()));
