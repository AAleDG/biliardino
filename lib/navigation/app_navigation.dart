import 'package:flutter/material.dart';

import '../presentation/app_presentation.dart';

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
