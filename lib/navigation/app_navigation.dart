import 'package:flutter/material.dart';

import '../screens/data_management_screen.dart';
import '../screens/history_screen.dart';
import '../screens/player_profile_screen.dart';

Future<void> openHistory(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const HistoryScreen()));
}

Future<void> openDataManagement(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const DataManagementScreen()));
}

Future<void> openPlayerProfile(BuildContext context, String playerId) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlayerProfileScreen(playerId: playerId),
    ),
  );
}
