import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/cubits/players/players_cubit.dart';
import 'package:biliardino/main.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/screens/history_screen.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/theme/app_theme.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  testWidgets('App si avvia e mostra la home', (WidgetTester tester) async {
    final repos = _Repos.build(players: const [], matches: const []);
    await tester.pumpWidget(BiliardinoApp(
      playerRepository: repos.playerRepo,
      matchRepository: repos.matchRepo,
    ));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets(
      'Le schermate principali non generano overflow su schermo piccolo',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sample = _sampleData();
    await _pumpHome(
      tester,
      home: const HomeScreen(),
      repos: sample,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final label in ['Partita', 'Storico', 'Classifica', 'Giocatori']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Lo storico raggruppa le partite per data',
      (WidgetTester tester) async {
    final sample = _sampleData();
    await _pumpHome(
      tester,
      home: const HistoryScreen(),
      repos: sample,
    );
    await tester.pumpAndSettle();

    expect(find.text('17 giugno 2026'), findsOneWidget);
    expect(find.text('Tutti i risultati'), findsOneWidget);
    expect(find.text('2 partite'), findsOneWidget);
    expect(find.text('2v2'), findsNWidgets(2));
    expect(find.text('Vittoria'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico mostra uno stato vuoto per filtro senza partite',
      (WidgetTester tester) async {
    final sample = _sampleDataNoMatchPlayerFirst();
    await _pumpHome(
      tester,
      home: const HistoryScreen(),
      repos: sample,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-player-p5')));
    await tester.ensureVisible(find.byKey(const ValueKey('history-apply-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-apply-filters')));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna partita trovata'), findsOneWidget);
    expect(find.text('Tutti i risultati · Elena Riserva Straordinaria'),
        findsWidgets);
    expect(find.text('Cambia filtro per consultare altri risultati.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico filtra le partite vinte da un giocatore',
      (WidgetTester tester) async {
    final sample = _sampleData();
    await _pumpHome(
      tester,
      home: const HistoryScreen(),
      repos: sample,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-player-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-filter-wins')));
    await tester.ensureVisible(find.byKey(const ValueKey('history-apply-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-apply-filters')));
    await tester.pumpAndSettle();

    expect(find.text('Ultimi 30 giorni'), findsNothing);
    expect(
        find.text('Tutti i risultati · Alessandro Antonio Delgaudio · Vinte'),
        findsWidgets);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('6'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico filtra le partite 1v1',
      (WidgetTester tester) async {
    final sample = _sampleDataMixedFormats();
    await _pumpHome(
      tester,
      home: const HistoryScreen(),
      repos: sample,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-filter-oneVsOne')));
    await tester.ensureVisible(find.byKey(const ValueKey('history-apply-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-apply-filters')));
    await tester.pumpAndSettle();

    expect(find.text('1v1 · Tutti i risultati'), findsWidgets);
    expect(find.text('1v1'), findsWidgets);
    expect(find.text('2v2'), findsNothing);
    expect(find.text('Ale'), findsOneWidget);
    expect(find.text('Mario / Max'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _Repos {
  _Repos({required this.playerRepo, required this.matchRepo});

  final PlayerRepository playerRepo;
  final MatchRepository matchRepo;

  static _Repos build({
    required List<Player> players,
    required List<GameMatch> matches,
  }) {
    final playerRepo = _MockPlayerRepository();
    final matchRepo = _MockMatchRepository();
    when(() => playerRepo.players).thenReturn(players);
    when(() => playerRepo.watchPlayers())
        .thenAnswer((_) => Stream.value(players));
    when(() => matchRepo.matches).thenReturn(matches);
    when(() => matchRepo.watchMatches())
        .thenAnswer((_) => Stream.value(matches));
    return _Repos(playerRepo: playerRepo, matchRepo: matchRepo);
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Widget home,
  required _Repos repos,
}) {
  return tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PlayerRepository>.value(value: repos.playerRepo),
        RepositoryProvider<MatchRepository>.value(value: repos.matchRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
          BlocProvider<PlayersCubit>(
            create: (_) => PlayersCubit(repos.playerRepo),
          ),
          BlocProvider<LeaderboardCubit>(
            create: (_) => LeaderboardCubit(
              playerRepository: repos.playerRepo,
              matchRepository: repos.matchRepo,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: home,
        ),
      ),
    ),
  );
}

_Repos _sampleData() {
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
  final matches = [
    GameMatch(
      id: 'm1',
      playedAt: now,
      mode: MatchMode.twoVsTwo,
      t1p1: 'p1',
      t1p2: 'p2',
      t2p1: 'p3',
      t2p2: 'p4',
      t1Score: 10,
      t2Score: 8,
      winningTeam: 1,
      scorerIds: const ['p1', 'p2', 'p1', 'p2', 'p1', 'p2', 'p1', 'p2', 'p1', 'p1', 'p3', 'p4', 'p3', 'p4', 'p3', 'p4', 'p3', 'p4'],
    ),
    GameMatch(
      id: 'm2',
      playedAt: now.subtract(const Duration(hours: 2)),
      mode: MatchMode.twoVsTwo,
      t1p1: 'p3',
      t1p2: 'p1',
      t2p1: 'p2',
      t2p2: 'p4',
      t1Score: 6,
      t2Score: 10,
      winningTeam: 2,
      scorerIds: const ['p3', 'p1', 'p3', 'p1', 'p3', 'p1', 'p2', 'p4', 'p2', 'p4', 'p2', 'p4', 'p2', 'p4', 'p2', 'p4'],
    ),
  ];
  return _Repos.build(players: players, matches: matches);
}

_Repos _sampleDataNoMatchPlayerFirst() {
  final base = _sampleData();
  final players = base.playerRepo.players;
  final reordered = [
    players[4],
    players[0],
    players[1],
    players[2],
    players[3],
  ];
  return _Repos.build(players: reordered, matches: base.matchRepo.matches);
}

_Repos _sampleDataMixedFormats() {
  final now = DateTime(2026, 6, 17, 12);
  final players = [
    Player(id: 'p1', name: 'Ale', createdAt: now),
    Player(id: 'p2', name: 'Luigi', createdAt: now),
    Player(id: 'p3', name: 'Mario', createdAt: now),
    Player(id: 'p4', name: 'Max', createdAt: now),
  ];
  final matches = [
    GameMatch(
      id: 'm1',
      playedAt: now,
      mode: MatchMode.twoVsTwo,
      t1p1: 'p1',
      t1p2: 'p2',
      t2p1: 'p3',
      t2p2: 'p4',
      t1Score: 5,
      t2Score: 2,
      winningTeam: 1,
      scorerIds: const ['p1', 'p2', 'p1', 'p2', 'p1', 'p3', 'p4'],
    ),
    GameMatch(
      id: 'm2',
      playedAt: now.subtract(const Duration(minutes: 8)),
      mode: MatchMode.oneVsOne,
      t1p1: 'p1',
      t1p2: '',
      t2p1: 'p4',
      t2p2: '',
      t1Score: 2,
      t2Score: 1,
      winningTeam: 1,
      scorerIds: const ['p1', 'p4', 'p1'],
    ),
  ];
  return _Repos.build(players: players, matches: matches);
}
