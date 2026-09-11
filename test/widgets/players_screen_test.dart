import 'dart:async';

import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/screens/player_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

class _ControlledPlayers extends PlayerRepository {
  _ControlledPlayers(super.db);
  bool fail = false;
  Completer<void>? barrier;

  Future<void> _run(Future<void> Function() operation) async {
    await barrier?.future;
    if (fail) throw StateError('Simulated failure');
    await operation();
  }

  @override
  Future<void> addPlayer(String name) => _run(() => super.addPlayer(name));
  @override
  Future<void> renamePlayer(Player p, String name) =>
      _run(() => super.renamePlayer(p, name));
  @override
  Future<void> togglePresent(Player p) => _run(() => super.togglePresent(p));
  @override
  Future<void> archivePlayer(Player p) => _run(() => super.archivePlayer(p));
  @override
  Future<void> reactivatePlayer(Player p) =>
      _run(() => super.reactivatePlayer(p));
}

Player _player(String id, String name, {bool archived = false}) => Player(
  id: id,
  name: name,
  createdAt: DateTime(2026),
  isPresent: !archived,
  isArchived: archived,
);

Future<(DesignFixture, _ControlledPlayers)> _mount(
  WidgetTester tester, {
  List<Player>? players,
  Size size = const Size(440, 956),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final fixture = DesignFixture(
    empty: true,
    playerRepositoryFactory: _ControlledPlayers.new,
  );
  fixture.database.players.addAll(players ?? [_player('p', 'Andrea')]);
  final repo = fixture.playersRepository as _ControlledPlayers;
  await fixture.load();
  await tester.pumpWidget(fixture.home);
  tester
      .element(find.byType(HomeScreen))
      .read<HomeCubit>()
      .select(HomeDestination.players);
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.dispose();
  });
  return (fixture, repo);
}

Future<void> _menu(WidgetTester tester, String id, String action) async {
  await tester.ensureVisible(find.byKey(ValueKey('player-actions-$id')));
  await tester.tap(find.byKey(ValueKey('player-actions-$id')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Archive group retains source ordering and profile activation', (
    tester,
  ) async {
    await _mount(
      tester,
      players: [
        _player('r', 'Roberto', archived: true),
        _player('a', 'Andrea'),
        _player('s', 'Sara'),
      ],
    );
    expect(find.text('ARCHIVIATI'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Sara')).dy,
      lessThan(tester.getTopLeft(find.text('ARCHIVIATI')).dy),
    );
    expect(find.byKey(const ValueKey('player-presence-r')), findsNothing);
    await tester.tap(find.text('Andrea'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PlayerProfileScreen>(find.byType(PlayerProfileScreen))
          .playerId,
      'a',
    );
  });

  testWidgets(
    'Empty and archive-only states keep add and reactivation reachable',
    (tester) async {
      final (fixture, _) = await _mount(tester, players: []);
      expect(find.text('Nessun giocatore'), findsOneWidget);
      expect(find.text('ARCHIVIATI'), findsNothing);
      fixture.database.players.add(_player('r', 'Roberto', archived: true));
      await fixture.playersRepository.load();
      await tester.pumpAndSettle();
      expect(find.text('0/0 presenti'), findsOneWidget);
      expect(find.text('ARCHIVIATI'), findsOneWidget);
      await _menu(tester, 'r', 'Riattiva');
      expect(find.text('ARCHIVIATI'), findsNothing);
      expect(find.text('Assente'), findsOneWidget);
      await tester.tap(find.text('NUOVO'));
      await tester.pumpAndSettle();
      expect(find.text('Nuovo giocatore'), findsOneWidget);
    },
  );

  testWidgets(
    'Rename retains draft on validation/failure and succeeds on retry',
    (tester) async {
      final (fixture, repo) = await _mount(
        tester,
        players: [_player('p', 'Andrea'), _player('g', 'Giulia')],
      );
      await _menu(tester, 'p', 'Modifica nome');
      await tester.enterText(find.byType(TextFormField), ' ');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(find.text('Inserisci un nome.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Giulia');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(
        find.text('Impossibile rinominare il giocatore. Controlla il nome.'),
        findsOneWidget,
      );
      expect(fixture.database.players.first.name, 'Andrea');
      await tester.enterText(find.byType(TextFormField), 'Alessandro');
      repo.fail = true;
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(fixture.database.players.first.name, 'Alessandro');
    },
  );

  testWidgets(
    'Presence failure and busy state preserve selection and allow retry',
    (tester) async {
      final (fixture, repo) = await _mount(tester);
      repo.barrier = Completer<void>();
      final presence = find.byKey(const ValueKey('player-presence-p'));
      await tester.tap(presence);
      await tester.pump();
      expect(tester.widget<Semantics>(presence).properties.enabled, false);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      expect(fixture.database.players.single.isPresent, true);
      repo.fail = true;
      repo.barrier!.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Impossibile aggiornare la presenza. Riprova.'),
        findsOneWidget,
      );
      repo.fail = false;
      repo.barrier = null;
      await tester.tap(presence);
      await tester.pumpAndSettle();
      expect(fixture.database.players.single.isPresent, false);
      expect(tester.widget<Semantics>(presence).properties.enabled, true);
    },
  );

  testWidgets('Archive and reactivate failures keep row and recover', (
    tester,
  ) async {
    final (fixture, repo) = await _mount(tester);
    await _menu(tester, 'p', 'Archivia');
    repo.fail = true;
    await tester.tap(find.byKey(const ValueKey('confirm-archive-player')));
    await tester.pumpAndSettle();
    expect(
      find.text('Impossibile archiviare il giocatore. Riprova.'),
      findsOneWidget,
    );
    expect(fixture.database.players.single.isArchived, false);
    repo.fail = false;
    await tester.tap(find.byKey(const ValueKey('confirm-archive-player')));
    await tester.pumpAndSettle();
    expect(find.text('ARCHIVIATI'), findsOneWidget);
    repo.fail = true;
    await _menu(tester, 'p', 'Riattiva');
    expect(
      find.text('Impossibile riattivare il giocatore. Riprova.'),
      findsOneWidget,
    );
    expect(fixture.database.players.single.isArchived, true);
    repo.fail = false;
    await _menu(tester, 'p', 'Riattiva');
    expect(fixture.database.players.single.isArchived, false);
  });

  testWidgets('Add failure and duplicate validation keep dialog usable', (
    tester,
  ) async {
    final (fixture, repo) = await _mount(tester);
    await tester.tap(find.text('NUOVO'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Andrea');
    await tester.tap(find.text('Aggiungi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Impossibile aggiungere il giocatore. Riprova.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'Giulia');
    repo.fail = true;
    await tester.tap(find.text('Aggiungi'));
    await tester.pumpAndSettle();
    expect(fixture.database.players.length, 1);
    repo.fail = false;
    await tester.tap(find.text('Aggiungi'));
    await tester.pumpAndSettle();
    expect(fixture.database.players.length, 2);
    expect(find.byType(TextFormField), findsNothing);
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('Large roster final row and controls at 200 percent $size', (
      tester,
    ) async {
      await _mount(
        tester,
        size: size,
        scale: 2,
        players: [
          for (var i = 0; i < 40; i++)
            _player('p$i', 'Giocatore $i Cognome Molto Lungo'),
          _player(
            'r',
            'Roberto Cognome Archiviato Lunghissimo',
            archived: true,
          ),
        ],
      );
      final scroll = find.byKey(const ValueKey('players-scroll'));
      final last = find.byKey(const ValueKey('player-actions-r'));
      await tester.scrollUntilVisible(
        last,
        400,
        scrollable: find
            .descendant(of: scroll, matching: find.byType(Scrollable))
            .first,
        maxScrolls: 100,
      );
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(tester.getSize(last).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(find.text('Riattiva'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
