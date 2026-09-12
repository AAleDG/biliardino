import 'package:biliardino/models/player.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/screens/player_profile_screen.dart';
import 'package:biliardino/screens/player_profile/profile_scene.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  for (final scenario in [
    (
      name: 'reference',
      size: const Size(402, 874),
      scale: 1.0,
      long: false,
      empty: false,
      missing: false,
    ),
    (
      name: 'compact',
      size: const Size(320, 568),
      scale: 2.0,
      long: true,
      empty: false,
      missing: false,
    ),
    (
      name: 'landscape',
      size: const Size(568, 320),
      scale: 2.0,
      long: true,
      empty: false,
      missing: false,
    ),
    (
      name: 'empty-archived',
      size: const Size(402, 874),
      scale: 1.0,
      long: false,
      empty: true,
      missing: false,
    ),
    (
      name: 'missing',
      size: const Size(320, 568),
      scale: 2.0,
      long: false,
      empty: true,
      missing: true,
    ),
  ]) {
    testWidgets('Figurina ${scenario.name} with real fonts and safe areas', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = DesignFixture();
      if (scenario.long) {
        fixture.database.players
            .replaceRange(0, fixture.database.players.length, [
              for (final player in fixture.database.players)
                Player(
                  id: player.id,
                  name: '${player.name} Cognome Molto Esteso',
                  createdAt: player.createdAt,
                  isPresent: player.isPresent,
                ),
            ]);
        final sample = fixture.database.matches.single;
        fixture.database.matches
          ..clear()
          ..addAll([
            for (var i = 0; i < 20; i++)
              sample.copyWith(playedAt: DateTime(2026, 1, i + 1)),
          ]);
        // Stable distinct records, real outcomes/scorer history; no precomputed metrics.
        for (var i = 0; i < fixture.database.matches.length; i++) {
          final map = fixture.database.matches[i].toMap();
          map['id'] = 'm$i';
          fixture.database.matches[i] = GameMatch.fromMap(map);
        }
      }
      if (scenario.empty) {
        fixture.database.matches.clear();
        final index = fixture.database.players.indexWhere((p) => p.id == 'p3');
        fixture.database.players[index] = fixture.database.players[index]
            .copyWith(isArchived: true, isPresent: false);
      }
      await fixture.load();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<PlayerRepository>.value(
                value: fixture.playersRepository,
              ),
              RepositoryProvider<MatchRepository>.value(
                value: fixture.matchesRepository,
              ),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.southAfrica(),
              home: PlayerProfileScreen(
                playerId: scenario.missing ? 'missing' : 'p3',
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage(ProfileScene.asset),
          tester.element(find.byType(PlayerProfileScreen)),
        ),
      );
      Future<void> capture(String suffix) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile('profile-figurina-${scenario.name}-$suffix.png'),
        );
      }

      await capture('top');
      if (!scenario.missing) {
        final scrollable = find
            .descendant(
              of: find.byKey(const ValueKey('profile-scroll')),
              matching: find.byType(Scrollable),
            )
            .first;
        if (scenario.long) {
          await tester.scrollUntilVisible(
            find.text('INTESA E RIVALITÀ'),
            220,
            scrollable: scrollable,
            maxScrolls: 50,
          );
          await capture('relationships');
        }
        await tester.scrollUntilVisible(
          find.text('STORICO PERSONALE'),
          220,
          scrollable: scrollable,
          maxScrolls: 50,
        );
        if (scenario.long) {
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('profile-match-m0')),
            220,
            scrollable: scrollable,
            maxScrolls: 100,
          );
        }
        await tester.drag(scrollable, const Offset(0, -250));
        await capture('bottom');
        if (scenario.long) {
          expect(
            find.byKey(const ValueKey('profile-match-m0')),
            findsOneWidget,
          );
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(fixture.dispose);
    });
  }
}
