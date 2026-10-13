import 'package:biliardino/models/player.dart';
import 'package:biliardino/models/player_badge.dart';
import 'package:biliardino/models/ranking_stats.dart';
import 'package:biliardino/models/player_stats.dart';
import 'package:biliardino/models/team_leaderboard_stats.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/design/ranking_podium.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

void main() {
  for (final scale in [2.0, 3.0]) {
    testWidgets(
      'ranking podium keeps every long recognition readable at ${scale}x text',
      (tester) async {
        await loadDesignFonts();
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final entries = _largeTextEntries();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.southAfrica(),
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: RankingPodium(
                      top: entries,
                      metricLabel: (stats) => '${stats.points} punti',
                      onOpen: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('podium-block-1')), findsNothing);
        for (final entry in entries) {
          expect(
            find.byKey(ValueKey('leaderboard-podium-${entry.id}')),
            findsOneWidget,
          );
          for (final badge in entry.badges) {
            expect(
              find.text(badge.label),
              badge.code == 'leader' || badge.code == 'bomber'
                  ? findsNWidgets(entries.length)
                  : findsOneWidget,
            );
          }
        }
      },
    );
  }

  testWidgets(
    'ordinary width keeps artwork and groups additional awards per entrant',
    (tester) async {
      await loadDesignFonts();
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final entries = _largeTextEntries().take(2).toList(growable: false);
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.southAfrica(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RankingPodium(
                top: entries,
                metricLabel: (stats) => '${stats.points} pt',
                onOpen: (id) => opened = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('podium-block-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('podium-block-2')), findsOneWidget);
      expect(find.text('Premio extra di Alex'), findsOneWidget);
      expect(find.text('Premio extra di Luca'), findsOneWidget);
      for (final entry in entries) {
        await tester.tap(find.byKey(ValueKey('leaderboard-podium-${entry.id}')));
        expect(opened, entry.id);
      }
    },
  );

  testWidgets('podium semantics expose profile action and extra awards', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();

    final entry = _largeTextEntries().first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.southAfrica(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RankingPodium(
              top: [entry],
              metricLabel: (_) => '9 pt',
              onOpen: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final podiumSemantics = tester.getSemantics(
      find.byKey(const ValueKey('leaderboard-podium-alex')),
    );
    expect(
      podiumSemantics,
      isSemantics(
        label: 'Posizione 1: Alex. 9 pt. Capoclassifica, Bomber',
        hint: 'Apri il profilo',
        isButton: true,
        hasTapAction: true,
      ),
    );
    const awardsLabel =
        'Riconoscimenti di Alex: Premio extra di Alex, Riconoscimento lungo di Alex';
    final awardsSemantics = tester.getSemantics(
      find.bySemanticsLabel(awardsLabel),
    );
    expect(awardsSemantics, isSemantics(label: awardsLabel));
    expect(tester.takeException(), isNull);
    semanticsHandle.dispose();
  });
}

List<RankingStats> _largeTextEntries() {
  final alex = Player(
    id: 'alex',
    isPresent: true,
    name: 'Alex',
    createdAt: DateTime(2026),
  );
  final luca = Player(
    id: 'luca',
    isPresent: true,
    name: 'Luca',
    createdAt: DateTime(2026),
  );
  final marco = Player(
    id: 'marco',
    isPresent: true,
    name: 'Marco',
    createdAt: DateTime(2026),
  );
  final entries = <RankingStats>[
    PlayerStats(
      player: alex,
      games: 4,
      wins: 4,
      losses: 0,
      goalsScored: 9,
      badges: _badges('Alex'),
    ),
    TeamLeaderboardStats(
      id: 'luca-marco',
      players: [luca, marco],
      games: 4,
      wins: 3,
      losses: 1,
      goalsScored: 7,
      badges: _badges('Luca'),
    ),
    PlayerStats(
      player: marco,
      games: 3,
      wins: 2,
      losses: 1,
      goalsScored: 5,
      badges: _badges('Marco'),
    ),
  ];
  return entries;
}

List<PlayerBadge> _badges(String owner) => [
  const PlayerBadge(
    code: 'leader',
    label: 'Capoclassifica',
    description: 'Miglior punteggio',
  ),
  const PlayerBadge(
    code: 'bomber',
    label: 'Bomber',
    description: 'Miglior marcatore',
  ),
  PlayerBadge(
    code: 'extra-$owner',
    label: 'Premio extra di $owner',
    description: 'Riconoscimento aggiuntivo',
  ),
  PlayerBadge(
    code: 'long-$owner',
    label: 'Riconoscimento lungo di $owner',
    description: 'Riconoscimento aggiuntivo con descrizione',
  ),
];
