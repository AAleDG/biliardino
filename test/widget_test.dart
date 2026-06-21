import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/main.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/state/app_state.dart';
import 'package:biliardino/theme/app_theme.dart';

void main() {
  testWidgets('App si avvia e mostra la home', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(),
        child: const BiliardinoApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Le schermate principali non generano overflow su schermo piccolo',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = _stateWithSampleData();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final label in ['Partita', 'Storico', 'Classifica', 'Giocatori']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

AppState _stateWithSampleData() {
  final now = DateTime(2026, 6, 17, 12);
  final players = [
    Player(
      id: 'p1',
      name: 'Alessandro Antonio Delgaudio',
      createdAt: now,
    ),
    Player(
      id: 'p2',
      name: 'Beatrice Lunghissimo Cognome',
      createdAt: now,
    ),
    Player(
      id: 'p3',
      name: 'Cristiano Nome Molto Esteso',
      createdAt: now,
    ),
    Player(
      id: 'p4',
      name: 'Daniela Super Competitiva',
      createdAt: now,
    ),
    Player(
      id: 'p5',
      name: 'Elena Riserva Straordinaria',
      createdAt: now,
      isPresent: false,
    ),
  ];
  final state = AppState()
    ..isLoading = false
    ..players = players
    ..matches = [
      GameMatch(
        id: 'm1',
        playedAt: now,
        t1p1: 'p1',
        t1p2: 'p2',
        t2p1: 'p3',
        t2p2: 'p4',
        t1Score: 10,
        t2Score: 8,
        winningTeam: 1,
      ),
      GameMatch(
        id: 'm2',
        playedAt: now.subtract(const Duration(hours: 2)),
        t1p1: 'p3',
        t1p2: 'p1',
        t2p1: 'p2',
        t2p2: 'p4',
        t1Score: 6,
        t2Score: 10,
        winningTeam: 2,
      ),
    ];
  return state;
}
