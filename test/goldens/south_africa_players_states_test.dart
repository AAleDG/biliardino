import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  for (final scenario in [
    'mixed',
    'empty',
    'archived',
    'large-text',
    'landscape',
  ]) {
    testWidgets('Players $scenario with real fonts', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final large = scenario == 'large-text' || scenario == 'landscape';
      tester.view.physicalSize = scenario == 'landscape'
          ? const Size(568, 320)
          : large
          ? const Size(320, 568)
          : const Size(440, 956);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
      tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = DesignFixture(
        empty: scenario == 'empty' || scenario == 'archived',
      );
      if (scenario != 'empty') {
        fixture.database.players.add(
          Player(
            id: 'r',
            name: 'Roberto',
            createdAt: DateTime(2026),
            isArchived: true,
            isPresent: false,
          ),
        );
      }
      if (large) {
        fixture.database.players[0] = fixture.database.players[0].copyWith(
          name: 'Alessandro Antonio Cognome Lunghissimo',
        );
      }
      await fixture.load();
      await tester.pumpWidget(
        RepaintBoundary(key: const ValueKey('capture'), child: fixture.home),
      );
      tester
          .element(find.byType(HomeScreen))
          .read<HomeCubit>()
          .select(HomeDestination.players);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('south-africa-players-$scenario.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
