import 'dart:async';

import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/cubits/players/players_cubit.dart';
import 'package:biliardino/main.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/match_rules.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/match_rules_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/screens/history_screen.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/screens/leaderboard_screen.dart';
import 'package:biliardino/screens/new_match_screen.dart';
import 'package:biliardino/screens/players_screen.dart';
import 'package:biliardino/screens/player_profile_screen.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/widgets/avatar.dart';
import 'package:biliardino/widgets/celebrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlayerRepository extends Mock implements PlayerRepository {}

class _MockMatchRepository extends Mock implements MatchRepository {}

class _MockMatchRulesRepository extends Mock implements MatchRulesRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(MatchMode.twoVsTwo);
    registerFallbackValue(<String>[]);
    registerFallbackValue(MatchRules.defaultRules);
    registerFallbackValue(_fallbackMatch());
    registerFallbackValue(
      Player(
        id: 'fallback-player',
        name: 'Fallback',
        createdAt: DateTime(2026),
        isPresent: false,
      ),
    );
    registerFallbackValue('');
  });

  testWidgets('App si avvia e mostra la home', (WidgetTester tester) async {
    final repos = _Repos.build(players: const [], matches: const []);
    await tester.pumpWidget(
      BiliardinoApp(
        playerRepository: repos.playerRepo,
        matchRepository: repos.matchRepo,
        matchRulesRepository: repos.matchRulesRepo,
      ),
    );
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
      await _pumpHome(tester, home: const HomeScreen(), repos: sample);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final label in ['Partita', 'Storico', 'Classifica', 'Giocatori']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Lo storico raggruppa le partite per data', (
    WidgetTester tester,
  ) async {
    final sample = _sampleData();
    await _pumpHome(tester, home: const HistoryScreen(), repos: sample);
    await tester.pumpAndSettle();

    expect(find.text('17 giugno 2026'), findsOneWidget);
    expect(find.text('Tutti i risultati'), findsOneWidget);
    expect(find.text('2 partite'), findsOneWidget);
    expect(find.text('2v2'), findsNWidgets(2));
    expect(find.text('Vittoria'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico mostra gli score a due cifre su una sola riga', (
    WidgetTester tester,
  ) async {
    final sample = _sampleData();
    await _pumpHome(tester, home: const HistoryScreen(), repos: sample);
    await tester.pumpAndSettle();

    final score = find.text('10').first;
    expect(tester.getSize(score).height, lessThan(60));
  });

  testWidgets('La Rivalita compare solo a squadre complete e apre il popup', (
    WidgetTester tester,
  ) async {
    final sample = _sampleData();
    await _pumpHome(tester, home: const NewMatchScreen(), repos: sample);
    await tester.pumpAndSettle();

    expect(find.text('Attiva Rivalita'), findsNothing);

    Future<void> assignTeam(String playerName, String chipLabel) async {
      await tester.scrollUntilVisible(
        find.text(playerName),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final row = find.ancestor(
        of: find.text(playerName),
        matching: find.byType(Card),
      );
      await tester.tap(
        find.descendant(of: row, matching: find.text(chipLabel)),
      );
      await tester.pumpAndSettle();
    }

    await assignTeam('Alessandro Antonio Delgaudio', 'S1');
    await assignTeam('Beatrice Lunghissimo Cognome', 'S1');
    await assignTeam('Cristiano Nome Molto Esteso', 'S2');
    await assignTeam('Daniela Super Competitiva', 'S2');

    expect(find.text('Attiva Rivalita'), findsOneWidget);

    await tester.tap(find.text('Attiva Rivalita'));
    await tester.pumpAndSettle();

    expect(find.text('Attivare Rivalita?'), findsOneWidget);
    expect(
      find.textContaining('Lo storico terra separati precedenti'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Le azioni generano squadre modificabili e abilitano il kickoff',
    (WidgetTester tester) async {
      final sample = _sampleData();
      await _pumpHome(tester, home: const NewMatchScreen(), repos: sample);
      await tester.pumpAndSettle();

      final randomAction = find.byKey(const ValueKey('random-teams-action'));
      final balancedAction = find.byKey(
        const ValueKey('balanced-teams-action'),
        skipOffstage: false,
      );
      expect(randomAction, findsOneWidget);
      expect(balancedAction, findsOneWidget);

      await tester.tap(randomAction);
      await tester.pump();
      final cubit = tester
          .element(find.byType(NewMatchScreen))
          .read<NewMatchCubit>();
      expect(cubit.state.teamsValid, isTrue);
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton).last)
            .onPressed,
        isNotNull,
      );

      final firstPlayerId = cubit.state.assignment.keys.first;
      final firstPlayer = cubit.state.players.firstWhere(
        (player) => player.id == firstPlayerId,
      );
      final selectedTeam = cubit.state.assignment[firstPlayerId];
      final playerCard = find.byKey(
        ValueKey('present-player-${firstPlayer.id}'),
      );
      await tester.scrollUntilVisible(
        playerCard,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: playerCard,
          matching: find.text(selectedTeam == 1 ? 'S1' : 'S2'),
        ),
      );
      await tester.pump();
      expect(cubit.state.assignment, isNot(contains(firstPlayerId)));
      expect(cubit.state.teamsValid, isFalse);

      await tester.scrollUntilVisible(
        balancedAction,
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(balancedAction);
      await tester.pump();
      expect(cubit.state.teamsValid, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('La generazione segue il cambio tra 2v2 e 1v1', (
    WidgetTester tester,
  ) async {
    final sample = _sampleData();
    await _pumpHome(tester, home: const NewMatchScreen(), repos: sample);
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 VS 1').first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('random-teams-action')));
    await tester.pump();

    final cubit = tester
        .element(find.byType(NewMatchScreen))
        .read<NewMatchCubit>();
    expect(cubit.state.mode, MatchMode.oneVsOne);
    expect(cubit.state.assignment, hasLength(2));
    expect(cubit.state.teamsValid, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Le azioni sono disabilitate durante il salvataggio regole', (
    WidgetTester tester,
  ) async {
    final sample = _sampleData();
    final pendingSave = Completer<void>();
    when(
      () => sample.matchRulesRepo.save(any()),
    ).thenAnswer((_) => pendingSave.future);
    await _pumpHome(tester, home: const NewMatchScreen(), repos: sample);
    await tester.pumpAndSettle();

    final cubit = tester
        .element(find.byType(NewMatchScreen))
        .read<NewMatchCubit>();
    final persistence = cubit.setRuleMode(MatchRuleMode.firstTo);
    expect(cubit.state.isPersistingRules, isTrue);
    await tester.pumpAndSettle();

    OutlinedButton action(Finder finder) => tester.widget(finder);
    final randomAction = find.byKey(const ValueKey('random-teams-action'));
    final balancedAction = find.byKey(const ValueKey('balanced-teams-action'));
    expect(action(randomAction).onPressed, isNull);
    expect(action(balancedAction).onPressed, isNull);

    pendingSave.complete();
    await persistence;
    expect(cubit.state.isPersistingRules, isFalse);
    await tester.pumpAndSettle();

    expect(action(randomAction).onPressed, isNotNull);
    expect(action(balancedAction).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico mostra uno stato vuoto per filtro senza partite', (
    WidgetTester tester,
  ) async {
    final sample = _sampleDataNoMatchPlayerFirst();
    await _pumpHome(tester, home: const HistoryScreen(), repos: sample);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-player-p5')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('history-apply-filters')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-apply-filters')));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna partita trovata'), findsOneWidget);
    expect(
      find.text('Tutti i risultati · Elena Riserva Straordinaria'),
      findsWidgets,
    );
    expect(
      find.text('Cambia filtro per consultare altri risultati.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico filtra le partite vinte da un giocatore', (
    WidgetTester tester,
  ) async {
    final sample = _sampleData();
    await _pumpHome(tester, home: const HistoryScreen(), repos: sample);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-player-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-filter-wins')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('history-apply-filters')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-apply-filters')));
    await tester.pumpAndSettle();

    expect(find.text('Ultimi 30 giorni'), findsNothing);
    expect(
      find.text('Tutti i risultati · Alessandro Antonio Delgaudio · Vinte'),
      findsWidgets,
    );
    expect(find.text('10'), findsOneWidget);
    expect(find.text('6'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico filtra le partite 1v1', (WidgetTester tester) async {
    final sample = _sampleDataMixedFormats();
    await _pumpHome(tester, home: const HistoryScreen(), repos: sample);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-filter-oneVsOne')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('history-apply-filters')),
    );
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

  testWidgets('Due giocatori presenti sono pronti per una partita 1v1', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026, 6, 17, 12);
    final repos = _Repos.build(
      players: [
        Player(id: 'p1', name: 'Ale', createdAt: now, isPresent: true),
        Player(id: 'p2', name: 'Luigi', createdAt: now, isPresent: true),
      ],
      matches: const [],
    );
    await _pumpHome(tester, home: const PlayersScreen(), repos: repos);
    await tester.pumpAndSettle();

    expect(find.text('2/2 presenti'), findsOneWidget);
    expect(find.text('Pronti a giocare'), findsOneWidget);
    expect(find.textContaining('Servono'), findsNothing);
  });

  testWidgets('Archiviazione richiede conferma', (tester) async {
    final player = Player(
      id: 'p1',
      name: 'Mario',
      createdAt: DateTime(2026),
      isPresent: true,
    );
    final repos = _Repos.build(players: [player], matches: const []);
    await _pumpHome(tester, home: const PlayersScreen(), repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('player-actions-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archivia'));
    await tester.pumpAndSettle();

    expect(find.text('Archivia giocatore'), findsOneWidget);
    verifyNever(() => repos.playerRepo.archivePlayer(any()));

    await tester.tap(find.byKey(const ValueKey('confirm-archive-player')));
    await tester.pumpAndSettle();

    verify(() => repos.playerRepo.archivePlayer(player)).called(1);
    expect(find.text('Archivia giocatore'), findsNothing);
  });

  testWidgets('Giocatore archiviato resta visibile e può essere riattivato', (
    tester,
  ) async {
    final player = Player(
      id: 'p1',
      name: 'Mario',
      createdAt: DateTime(2026),
      isPresent: false,
      isArchived: true,
    );
    final repos = _Repos.build(players: [player], matches: const []);
    await _pumpHome(tester, home: const PlayersScreen(), repos: repos);
    await tester.pumpAndSettle();

    expect(find.text('Mario'), findsOneWidget);
    expect(find.text('Archiviato'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    await tester.tap(find.byKey(const ValueKey('player-actions-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riattiva'));
    await tester.pumpAndSettle();

    verify(() => repos.playerRepo.reactivatePlayer(player)).called(1);
  });

  testWidgets('Il profilo mostra statistiche avanzate e storico filtrato', (
    WidgetTester tester,
  ) async {
    final repos = _sampleData();
    await _pumpHome(
      tester,
      home: const PlayerProfileScreen(playerId: 'p1'),
      repos: repos,
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('FORMA RECENTE'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('FORMA RECENTE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('TESTA A TESTA'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('STORICO PERSONALE'), findsOneWidget);
    expect(find.text('2 partite'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Il profilo mostra tutti i nomi delle relazioni a pari merito', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repos = _tiedRelationshipData();
    await _pumpHome(
      tester,
      home: const PlayerProfileScreen(playerId: 'p1'),
      repos: repos,
    );
    await tester.pumpAndSettle();

    const tiedNames = 'Cristiano Nome Molto Esteso, Daniela Super Competitiva';
    await tester.scrollUntilVisible(
      find.text('INTESA E RIVALITÀ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final relationshipNames = tester.widget<Text>(find.text(tiedNames));
    expect(relationshipNames.maxLines, isNull);
    expect(relationshipNames.overflow, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Il nome nella classifica apre il profilo giocatore', (
    WidgetTester tester,
  ) async {
    final repos = _sampleData();
    await _pumpHome(tester, home: const LeaderboardScreen(), repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alessandro Antonio Delgaudio').first);
    await tester.pumpAndSettle();

    expect(find.text('PROFILO'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('STORICO PERSONALE'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('STORICO PERSONALE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Le regole partono da punteggio libero nel setup', (
    WidgetTester tester,
  ) async {
    final repos = _sampleData();
    await _pumpHome(tester, home: const NewMatchScreen(), repos: repos);
    await tester.pumpAndSettle();

    expect(find.text('REGOLE PUNTEGGIO'), findsOneWidget);
    expect(find.text('Libero'), findsOneWidget);
    expect(find.text('Primo a N'), findsOneWidget);
    expect(find.text('Goal vittoria'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('First-to-N richiede conferma prima del salvataggio', (
    WidgetTester tester,
  ) async {
    final repos = _sampleData(
      rules: const MatchRules(
        mode: MatchRuleMode.firstTo,
        targetScore: 2,
        winByTwo: false,
      ),
    );
    await _pumpHome(tester, home: const NewMatchScreen(), repos: repos);
    await tester.pumpAndSettle();

    await _assignTeam(tester, 'Alessandro Antonio Delgaudio', 'S1');
    await _assignTeam(tester, 'Beatrice Lunghissimo Cognome', 'S1');
    await _assignTeam(tester, 'Cristiano Nome Molto Esteso', 'S2');
    await _assignTeam(tester, 'Daniela Super Competitiva', 'S2');
    await tester.tap(find.text('INIZIA PARTITA'));
    await tester.pumpAndSettle();

    expect(find.text('PRIMO A 2'), findsOneWidget);
    await tester.tap(find.text('+1 GOAL').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alessandro Antonio Delgaudio').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 700));

    expect(find.text('Registrare la vittoria?'), findsNothing);

    await tester.tap(find.text('+1 GOAL').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beatrice Lunghissimo Cognome').last);
    await tester.pumpAndSettle();

    expect(find.text('Registrare la vittoria?'), findsOneWidget);
    expect(find.text('Registra'), findsOneWidget);
    verifyNever(
      () => repos.matchRepo.addMatch(
        mode: any(named: 'mode'),
        isRivalry: any(named: 'isRivalry'),
        team1: any(named: 'team1'),
        team2: any(named: 'team2'),
        score1: any(named: 'score1'),
        score2: any(named: 'score2'),
        scorerIds: any(named: 'scorerIds'),
      ),
    );

    await tester.tap(find.text('Registra'));
    await tester.pumpAndSettle();

    verify(
      () => repos.matchRepo.addMatch(
        mode: MatchMode.twoVsTwo,
        isRivalry: false,
        team1: ['p1', 'p2'],
        team2: ['p3', 'p4'],
        score1: 2,
        score2: 0,
        scorerIds: ['p1', 'p2'],
      ),
    ).called(1);
    expect(find.text('VITTORIA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'La classifica vuota per giocatori senza partite disabilita export CSV',
    (WidgetTester tester) async {
      final repos = _Repos.build(
        players: [
          Player(
            id: 'solo',
            name: 'Solo',
            createdAt: DateTime(2026),
            isPresent: true,
          ),
        ],
        matches: const [],
      );
      await _pumpHome(tester, home: const LeaderboardScreen(), repos: repos);
      await tester.pumpAndSettle();

      final exportButton = tester.widget<IconButton>(
        find.byKey(const ValueKey('leaderboard-export-csv')),
      );

      expect(find.text('Nessuna partita giocata'), findsOneWidget);
      expect(find.text('Solo'), findsNothing);
      expect(exportButton.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('La vittoria sparisce quando si lascia il tab partita', (
    WidgetTester tester,
  ) async {
    final repos = _sampleData();
    await _pumpHome(tester, home: const HomeScreen(), repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Partita'));
    await tester.pumpAndSettle();
    await _assignTeam(tester, 'Alessandro Antonio Delgaudio', 'S1');
    await _assignTeam(tester, 'Beatrice Lunghissimo Cognome', 'S1');
    await _assignTeam(tester, 'Cristiano Nome Molto Esteso', 'S2');
    await _assignTeam(tester, 'Daniela Super Competitiva', 'S2');
    await tester.tap(find.text('INIZIA PARTITA'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+1 GOAL').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alessandro Antonio Delgaudio').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 1200));
    await tester.tap(find.text('REGISTRA RISULTATO'));
    await tester.pumpAndSettle();

    expect(find.text('VITTORIA'), findsOneWidget);

    tester.element(find.byType(HomeScreen)).read<HomeCubit>().selectTab(3);
    await tester.pumpAndSettle();

    expect(find.text('VITTORIA'), findsNothing);
    expect(find.text('CLASSIFICA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cambiare tab senza vittoria preserva la composizione', (
    WidgetTester tester,
  ) async {
    final repos = _sampleData();
    await _pumpHome(tester, home: const HomeScreen(), repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Partita'));
    await tester.pumpAndSettle();
    await _assignTeam(tester, 'Alessandro Antonio Delgaudio', 'S1');
    await _assignTeam(tester, 'Beatrice Lunghissimo Cognome', 'S1');

    final cubit = tester.element(find.byType(HomeScreen)).read<NewMatchCubit>();
    expect(cubit.state.assignment, {'p1': 1, 'p2': 1});

    await tester.tap(find.text('Storico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partita'));
    await tester.pumpAndSettle();

    expect(cubit.state.assignment, {'p1': 1, 'p2': 1});
    expect(cubit.state.kickedOff, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico richiede marcatori legacy espliciti', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repos = _legacyScorerData();
    await _pumpHome(tester, home: const HistoryScreen(), repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Azioni partita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correggi'));
    await tester.pumpAndSettle();

    expect(find.text('Marcatori squadra 1'), findsOneWidget);
    expect(_scorerDropdown('Gol 1'), findsOneWidget);

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(
      find.text('Assegna tutti i marcatori prima di salvare.'),
      findsOneWidget,
    );
    expect(repos.updatedMatches, isEmpty);

    await tester.ensureVisible(_scorerDropdown('Gol 1'));
    await tester.pumpAndSettle();
    await tester.tap(_scorerDropdown('Gol 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ale').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(repos.updatedMatches, hasLength(1));
    expect(repos.updatedMatches.single.scorerIds, ['p1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico non inventa marcatori mancanti parziali', (
    WidgetTester tester,
  ) async {
    await _setTallTestViewport(tester);
    final repos = _partialScorerData();
    await _pumpHome(tester, home: const HistoryScreen(), repos: repos);
    await tester.pumpAndSettle();
    await _openFirstMatchEditDialog(tester);

    expect(_scorerDropdown('Gol 1'), findsOneWidget);
    expect(_scorerDropdown('Gol 2'), findsOneWidget);

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(
      find.text('Assegna tutti i marcatori prima di salvare.'),
      findsOneWidget,
    );
    expect(repos.updatedMatches, isEmpty);

    await _selectDropdownValue(
      tester,
      dropdown: _scorerDropdown('Gol 2'),
      valueText: 'Ale',
    );
    await tester.ensureVisible(find.text('Salva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(repos.updatedMatches, hasLength(1));
    expect(repos.updatedMatches.single.scorerIds, ['p1', 'p1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lo storico invalida marcatori se cambia la squadra', (
    WidgetTester tester,
  ) async {
    await _setTallTestViewport(tester);
    final repos = _teamChangeScorerData();
    await _pumpHome(tester, home: const HistoryScreen(), repos: repos);
    await tester.pumpAndSettle();
    await _openFirstMatchEditDialog(tester);

    await _selectDropdownValue(
      tester,
      dropdown: _dropdownByLabel('Giocatore 1').first,
      valueText: 'Nora',
    );
    await tester.ensureVisible(find.text('Salva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(
      find.text('Assegna tutti i marcatori prima di salvare.'),
      findsOneWidget,
    );
    expect(repos.updatedMatches, isEmpty);

    await _selectDropdownValue(
      tester,
      dropdown: _scorerDropdown('Gol 1'),
      valueText: 'Bea',
    );
    await tester.ensureVisible(find.text('Salva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(repos.updatedMatches, hasLength(1));
    expect(repos.updatedMatches.single.team1, ['p5', 'p2']);
    expect(repos.updatedMatches.single.scorerIds, ['p2']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Toccare una card apre i dettagli della partita', (
    WidgetTester tester,
  ) async {
    final repos = _sampleData();
    await _pumpHome(tester, home: const HistoryScreen(), repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-match-m1')));
    await tester.pumpAndSettle();

    expect(find.text('Dettagli partita'), findsOneWidget);
    expect(find.text('17/06/2026 · 12:00'), findsOneWidget);
    expect(find.text('2v2'), findsWidgets);
    expect(
      find.text(
        'Alessandro Antonio Delgaudio / Beatrice Lunghissimo Cognome  10',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('match-details-edit')), findsOneWidget);
    expect(find.byKey(const ValueKey('match-details-delete')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('I dettagli restano accessibili in landscape con testo grande', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final repos = _sampleData();
    await _pumpHome(tester, home: const HistoryScreen(), repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-match-m1')));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('match-details-edit')),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('match-details-edit')), findsOneWidget);
    expect(find.byKey(const ValueKey('match-details-delete')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Eliminare dai dettagli richiede conferma', (
    WidgetTester tester,
  ) async {
    final repos = _sampleData();
    await _pumpHome(tester, home: const HistoryScreen(), repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-match-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('match-details-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Eliminare partita?'), findsOneWidget);
    verifyNever(() => repos.matchRepo.deleteMatch(any()));

    await tester.tap(find.text('Elimina').last);
    await tester.pumpAndSettle();

    verify(() => repos.matchRepo.deleteMatch('m1')).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Un errore di eliminazione mantiene la partita e informa', (
    WidgetTester tester,
  ) async {
    final repos = _sampleData();
    when(
      () => repos.matchRepo.deleteMatch('m1'),
    ).thenThrow(StateError('database unavailable'));
    await _pumpHome(tester, home: const HistoryScreen(), repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-match-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('match-details-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina').last);
    await tester.pumpAndSettle();

    expect(find.text('Impossibile eliminare la partita.'), findsOneWidget);
    expect(find.byKey(const ValueKey('history-match-m1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'I selettori della partita espongono stato e target accessibili',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpHome(
          tester,
          home: const NewMatchScreen(),
          repos: _sampleData(),
        );
        await tester.pumpAndSettle();

        final oneVsOne = find.byKey(const ValueKey('match-mode-one-vs-one'));
        expect(
          tester.getSemantics(oneVsOne),
          matchesSemantics(
            label: '1 VS 1: 2 giocatori totali, uno per squadra.',
            isButton: true,
            isSelected: false,
            hasSelectedState: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );

        await tester.tap(find.text('1 VS 1').first);
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(oneVsOne),
          matchesSemantics(
            label: '1 VS 1: 2 giocatori totali, uno per squadra.',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );

        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('present-player-p1')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final teamOneChip = find.byKey(const ValueKey('team-chip-p1-team-1'));
        expect(teamOneChip, findsOneWidget);
        expect(tester.getSize(teamOneChip).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(teamOneChip).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(teamOneChip),
          matchesSemantics(
            label: 'Alessandro Antonio Delgaudio, Squadra 1',
            isButton: true,
            isSelected: false,
            hasSelectedState: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('Il controllo presenza identifica il giocatore e il suo stato', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpHome(
        tester,
        home: const PlayersScreen(),
        repos: _sampleData(),
      );
      await tester.pumpAndSettle();

      final presence = find.byKey(const ValueKey('player-presence-p1'));
      expect(
        tester.getSemantics(presence),
        matchesSemantics(
          label: 'Presenza di Alessandro Antonio Delgaudio',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('I controlli del punteggio espongono squadra, stato e target', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpHome(
        tester,
        home: const NewMatchScreen(),
        repos: _sampleData(),
      );
      await tester.pumpAndSettle();

      await _assignTeam(tester, 'Alessandro Antonio Delgaudio', 'S1');
      await _assignTeam(tester, 'Beatrice Lunghissimo Cognome', 'S1');
      await _assignTeam(tester, 'Cristiano Nome Molto Esteso', 'S2');
      await _assignTeam(tester, 'Daniela Super Competitiva', 'S2');
      await tester.ensureVisible(find.text('INIZIA PARTITA'));
      await tester.tap(find.text('INIZIA PARTITA'));
      await tester.pumpAndSettle();

      final addGoal = find.byKey(const ValueKey('score-add-team-1'));
      expect(
        tester.getSemantics(addGoal),
        matchesSemantics(
          label: 'Aggiungi un goal a SQUADRA 1. Punteggio attuale 0.',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      final score = find.byKey(const ValueKey('score-team-1'));
      expect(
        tester.getSemantics(score),
        matchesSemantics(label: 'Punteggio SQUADRA 1: 0', isLiveRegion: true),
      );

      final undoGoal = find.byKey(const ValueKey('score-undo-team-1'));
      expect(tester.getSize(undoGoal).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(undoGoal),
        matchesSemantics(
          label: 'Annulla ultimo goal di SQUADRA 1',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'Le celebrazioni annunciano il goal e isolano il risultato finale',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      CelebrationOverlayHandle? victoryHandle;
      var backgroundTaps = 0;
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      key: const ValueKey('show-goal'),
                      onPressed: () => Celebrations.showGoal(
                        context,
                        color: NttColors.team1,
                        teamLabel: 'SQUADRA 1',
                      ),
                      child: const Text('Mostra goal'),
                    ),
                    ElevatedButton(
                      key: const ValueKey('show-victory'),
                      onPressed: () {
                        victoryHandle = Celebrations.showVictory(
                          context,
                          color: NttColors.team1,
                          teamLabel: 'SQUADRA 1',
                          playerNames: const ['Ale', 'Bea'],
                          winnerScore: 3,
                          loserScore: 1,
                          onChangeTeams: () {},
                          onRematch: () {},
                        );
                      },
                      child: const Text('Mostra risultato'),
                    ),
                    GestureDetector(
                      onTap: () => backgroundTaps += 1,
                      child: const SizedBox(
                        key: ValueKey('background-action'),
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('show-goal')));
        await tester.pump();
        expect(
          tester.getSemantics(find.byKey(const ValueKey('goal-overlay'))),
          matchesSemantics(label: 'Goal. SQUADRA 1', isLiveRegion: true),
        );
        await tester.pump(const Duration(milliseconds: 1200));

        await tester.tap(find.byKey(const ValueKey('show-victory')));
        await tester.pump();
        expect(
          tester.getSemantics(find.byKey(const ValueKey('victory-overlay'))),
          matchesSemantics(
            label: 'Vittoria: SQUADRA 1. Ale e Bea. Punteggio 3 a 1.',
            isLiveRegion: true,
            namesRoute: true,
            scopesRoute: true,
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('background-action')),
          warnIfMissed: false,
        );
        expect(backgroundTaps, 0);
        expect(find.text('RIVINCITA'), findsOneWidget);
      } finally {
        victoryHandle?.dismiss();
        semantics.dispose();
      }
    },
  );

  test('I colori dinamici mantengono il contrasto sul pannello HUD', () {
    final List<String> names = [
      '',
      'Alessandro Antonio Delgaudio',
      'Beatrice Lunghissimo Cognome',
      'Cristiano Nome Molto Esteso',
      ...List.generate(360, (index) => 'Player $index'),
    ];

    for (final name in names) {
      final ratio = _contrastRatio(hudColorForName(name), NttColors.surfaceMid);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'Contrast for "$name" was $ratio',
      );
    }
  });

  testWidgets(
    'Lo storico annuncia squadra, punteggio e vittoria senza affidarsi al colore',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpHome(
          tester,
          home: const HistoryScreen(),
          repos: _sampleData(),
        );
        await tester.pumpAndSettle();

        final teamResult = find.byKey(const ValueKey('history-team-m1-team-1'));
        expect(
          tester.getSemantics(teamResult),
          matchesSemantics(
            label:
                'Squadra 1: Alessandro Antonio Delgaudio / '
                'Beatrice Lunghissimo Cognome, punteggio 10, vittoria',
          ),
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'La forma recente espone vittoria e sconfitta senza affidarsi al colore',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpHome(
          tester,
          home: const PlayerProfileScreen(playerId: 'p1'),
          repos: _sampleData(),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('FORMA RECENTE'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Vittoria'), findsOneWidget);
        expect(find.bySemanticsLabel('Sconfitta'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'La classifica espone il podium come azione con contesto completo',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpHome(
          tester,
          home: const LeaderboardScreen(),
          repos: _sampleData(),
        );
        await tester.pumpAndSettle();

        final podium = find.byKey(const ValueKey('leaderboard-podium-p2'));
        expect(
          tester.getSemantics(podium),
          matchesSemantics(
            label: 'Posizione 1: Beatrice Lunghissimo Cognome. 6 pt.',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Le schermate principali restano stabili con testo al 200 percento',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pumpHome(tester, home: const HomeScreen(), repos: _sampleData());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final label in ['Partita', 'Storico', 'Classifica', 'Giocatori']) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Le animazioni decorative rispettano la preferenza riduci movimento',
    (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await _pumpHome(
        tester,
        home: const LeaderboardScreen(),
        repos: _sampleData(),
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Il comando per aprire i filtri mantiene un target di almeno 48dp',
    (WidgetTester tester) async {
      await _pumpHome(
        tester,
        home: const HistoryScreen(),
        repos: _sampleData(),
      );
      await tester.pumpAndSettle();

      final openFilters = find.byKey(const ValueKey('history-open-filters'));
      expect(tester.getSize(openFilters).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(openFilters).height, greaterThanOrEqualTo(48));
    },
  );
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

class _Repos {
  _Repos({
    required this.playerRepo,
    required this.matchRepo,
    required this.matchRulesRepo,
    required this.updatedMatches,
  });

  final PlayerRepository playerRepo;
  final MatchRepository matchRepo;
  final MatchRulesRepository matchRulesRepo;
  final List<GameMatch> updatedMatches;

  static _Repos build({
    required List<Player> players,
    required List<GameMatch> matches,
    MatchRules rules = MatchRules.defaultRules,
  }) {
    final playerRepo = _MockPlayerRepository();
    final matchRepo = _MockMatchRepository();
    final matchRulesRepo = _MockMatchRulesRepository();
    final updatedMatches = <GameMatch>[];
    when(() => playerRepo.players).thenReturn(players);
    when(
      () => playerRepo.watchPlayers(),
    ).thenAnswer((_) => Stream.value(players));
    when(() => playerRepo.archivePlayer(any())).thenAnswer((_) async {});
    when(() => playerRepo.reactivatePlayer(any())).thenAnswer((_) async {});
    when(() => playerRepo.renamePlayer(any(), any())).thenAnswer((_) async {});
    when(() => matchRepo.matches).thenReturn(matches);
    when(
      () => matchRepo.watchMatches(),
    ).thenAnswer((_) => Stream.value(matches));
    when(
      () => matchRepo.addMatch(
        mode: any(named: 'mode'),
        isRivalry: any(named: 'isRivalry'),
        team1: any(named: 'team1'),
        team2: any(named: 'team2'),
        score1: any(named: 'score1'),
        score2: any(named: 'score2'),
        scorerIds: any(named: 'scorerIds'),
      ),
    ).thenAnswer((_) async {});
    when(() => matchRepo.updateMatch(any())).thenAnswer((invocation) async {
      updatedMatches.add(invocation.positionalArguments.single as GameMatch);
    });
    when(() => matchRepo.deleteMatch(any())).thenAnswer((_) async {});
    when(() => matchRulesRepo.rules).thenReturn(rules);
    when(() => matchRulesRepo.load()).thenAnswer((_) async {});
    when(() => matchRulesRepo.save(any())).thenAnswer((_) async {});
    return _Repos(
      playerRepo: playerRepo,
      matchRepo: matchRepo,
      matchRulesRepo: matchRulesRepo,
      updatedMatches: updatedMatches,
    );
  }
}

Finder _scorerDropdown(String label) {
  return _dropdownByLabel(label);
}

Finder _dropdownByLabel(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<String> &&
        widget.decoration.labelText == label,
  );
}

Future<void> _setTallTestViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openFirstMatchEditDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Azioni partita').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Correggi'));
  await tester.pumpAndSettle();
}

Future<void> _selectDropdownValue(
  WidgetTester tester, {
  required Finder dropdown,
  required String valueText,
}) async {
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(valueText).last);
  await tester.pumpAndSettle();
}

Future<void> _assignTeam(
  WidgetTester tester,
  String playerName,
  String chipLabel,
) async {
  if (find.text(playerName).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(playerName),
      120,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(find.text(playerName));
  }
  await tester.pumpAndSettle();
  final row = find.ancestor(
    of: find.text(playerName),
    matching: find.byType(Card),
  );
  await tester.tap(find.descendant(of: row, matching: find.text(chipLabel)));
  await tester.pumpAndSettle();
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
        RepositoryProvider<MatchRulesRepository>.value(
          value: repos.matchRulesRepo,
        ),
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
          BlocProvider<NewMatchCubit>(
            create: (_) => NewMatchCubit(
              playerRepository: repos.playerRepo,
              matchRepository: repos.matchRepo,
              matchRulesRepository: repos.matchRulesRepo,
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: home),
      ),
    ),
  );
}

_Repos _sampleData({MatchRules rules = MatchRules.defaultRules}) {
  final now = DateTime(2026, 6, 17, 12);
  final players = [
    Player(
      id: 'p1',
      name: 'Alessandro Antonio Delgaudio',
      createdAt: now,
      isPresent: true,
    ),
    Player(
      id: 'p2',
      name: 'Beatrice Lunghissimo Cognome',
      createdAt: now,
      isPresent: true,
    ),
    Player(
      id: 'p3',
      name: 'Cristiano Nome Molto Esteso',
      createdAt: now,
      isPresent: true,
    ),
    Player(
      id: 'p4',
      name: 'Daniela Super Competitiva',
      createdAt: now,
      isPresent: true,
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
      scorerIds: const [
        'p1',
        'p2',
        'p1',
        'p2',
        'p1',
        'p2',
        'p1',
        'p2',
        'p1',
        'p1',
        'p3',
        'p4',
        'p3',
        'p4',
        'p3',
        'p4',
        'p3',
        'p4',
      ],
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
      scorerIds: const [
        'p3',
        'p1',
        'p3',
        'p1',
        'p3',
        'p1',
        'p2',
        'p4',
        'p2',
        'p4',
        'p2',
        'p4',
        'p2',
        'p4',
        'p2',
        'p4',
      ],
    ),
  ];
  return _Repos.build(players: players, matches: matches, rules: rules);
}

_Repos _tiedRelationshipData() {
  final sample = _sampleData();
  return _Repos.build(
    players: sample.playerRepo.players,
    matches: [sample.matchRepo.matches.first],
  );
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
    Player(id: 'p1', name: 'Ale', createdAt: now, isPresent: true),
    Player(id: 'p2', name: 'Luigi', createdAt: now, isPresent: true),
    Player(id: 'p3', name: 'Mario', createdAt: now, isPresent: true),
    Player(id: 'p4', name: 'Max', createdAt: now, isPresent: true),
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

_Repos _legacyScorerData() {
  final now = DateTime(2026, 6, 17, 12);
  final players = [
    Player(id: 'p1', name: 'Ale', createdAt: now, isPresent: true),
    Player(id: 'p2', name: 'Max', createdAt: now, isPresent: true),
  ];
  final matches = [
    GameMatch(
      id: 'legacy',
      playedAt: now,
      mode: MatchMode.oneVsOne,
      t1p1: 'p1',
      t1p2: '',
      t2p1: 'p2',
      t2p2: '',
      t1Score: 1,
      t2Score: 0,
      winningTeam: 1,
      scorerIds: const [],
    ),
  ];
  return _Repos.build(players: players, matches: matches);
}

_Repos _partialScorerData() {
  final now = DateTime(2026, 6, 17, 12);
  final players = [
    Player(id: 'p1', name: 'Ale', createdAt: now, isPresent: true),
    Player(id: 'p2', name: 'Max', createdAt: now, isPresent: true),
  ];
  final matches = [
    GameMatch(
      id: 'partial',
      playedAt: now,
      mode: MatchMode.oneVsOne,
      t1p1: 'p1',
      t1p2: '',
      t2p1: 'p2',
      t2p2: '',
      t1Score: 2,
      t2Score: 0,
      winningTeam: 1,
      scorerIds: const ['p1'],
    ),
  ];
  return _Repos.build(players: players, matches: matches);
}

_Repos _teamChangeScorerData() {
  final now = DateTime(2026, 6, 17, 12);
  final players = [
    Player(id: 'p1', name: 'Ale', createdAt: now, isPresent: true),
    Player(id: 'p2', name: 'Bea', createdAt: now, isPresent: true),
    Player(id: 'p3', name: 'Ciro', createdAt: now, isPresent: true),
    Player(id: 'p4', name: 'Dina', createdAt: now, isPresent: true),
    Player(id: 'p5', name: 'Nora', createdAt: now, isPresent: true),
  ];
  final matches = [
    GameMatch(
      id: 'team-change',
      playedAt: now,
      mode: MatchMode.twoVsTwo,
      t1p1: 'p1',
      t1p2: 'p2',
      t2p1: 'p3',
      t2p2: 'p4',
      t1Score: 1,
      t2Score: 0,
      winningTeam: 1,
      scorerIds: const ['p1'],
    ),
  ];
  return _Repos.build(players: players, matches: matches);
}

GameMatch _fallbackMatch() {
  return GameMatch(
    id: 'fallback',
    playedAt: DateTime(2026),
    mode: MatchMode.oneVsOne,
    t1p1: 'p1',
    t1p2: '',
    t2p1: 'p2',
    t2p2: '',
    t1Score: 1,
    t2Score: 0,
    winningTeam: 1,
    scorerIds: const ['p1'],
  );
}
