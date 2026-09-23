import 'package:flutter/material.dart';

import '../presentation/app_presentation.dart';

Future<void> openHistory(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PresentationPage(AppPage.history),
    ),
  );
}

Future<void> openDataManagement(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PresentationPage(AppPage.data),
    ),
  );
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
