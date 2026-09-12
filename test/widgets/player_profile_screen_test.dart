import 'package:biliardino/cubits/player_profile/player_profile_cubit.dart';
import 'package:biliardino/cubits/player_profile/player_profile_state.dart';
import 'package:biliardino/navigation/app_navigation.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player_profile_stats.dart';
import 'package:biliardino/screens/player_profile/profile_sections.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:biliardino/screens/player_profile_screen.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

void main() {
  late DesignFixture fixture;
  setUp(() async {
    fixture = DesignFixture();
    await fixture.load();
  });
  tearDown(() => fixture.dispose());

  Widget app(Widget home) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<PlayerRepository>.value(
        value: fixture.playersRepository,
      ),
      RepositoryProvider<MatchRepository>.value(
        value: fixture.matchesRepository,
      ),
    ],
    child: MaterialApp(theme: AppTheme.southAfrica(), home: home),
  );

  PlayerProfileCubit owner(WidgetTester tester) => tester
      .element(find.byType(BlocBuilder<PlayerProfileCubit, PlayerProfileState>))
      .read<PlayerProfileCubit>();

  testWidgets('profile route owns its state and disposes it on back', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openPlayerProfile(context, 'p3'),
              child: const Text('Open profile'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    final cubit = owner(tester);
    final closed = cubit.stream.drain<void>();
    expect(cubit.state.player!.name, 'Marco');
    expect(find.text('Marco'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open profile'), findsOneWidget);
    // Repository cancellation crosses the real-async and widget-test zones.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await closed;
    expect(cubit.isClosed, isTrue);
    await tester.runAsync(
      () => fixture.playersRepository.togglePresent(
        fixture.playersRepository.players.first,
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('changing player ID replaces the scoped owner', (tester) async {
    await tester.pumpWidget(app(const PlayerProfileScreen(playerId: 'p3')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    final original = owner(tester);
    final closed = original.stream.drain<void>();
    await tester.pumpWidget(app(const PlayerProfileScreen(playerId: 'p0')));
    await tester.pumpAndSettle();
    // Repository cancellation crosses the real-async and widget-test zones.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await closed;
    expect(original.isClosed, isTrue);
    expect(owner(tester).state.player!.name, 'Andrea');
    expect(find.text('Andrea'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('repository rename and removal update the visible profile', (
    tester,
  ) async {
    await tester.pumpWidget(app(const PlayerProfileScreen(playerId: 'p3')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => fixture.playersRepository.renamePlayer(
        owner(tester).state.player!,
        'Mario',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mario'), findsOneWidget);
    fixture.database.players.removeWhere((player) => player.id == 'p3');
    await tester.runAsync(fixture.playersRepository.load);
    await tester.pumpAndSettle();
    expect(find.text('Giocatore non trovato.'), findsOneWidget);
    expect(find.text('Mario'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'one versus one preserves partial relationships and legacy goals',
    (tester) async {
      fixture.database.matches
        ..clear()
        ..add(
          GameMatch(
            id: 'legacy',
            playedAt: DateTime(2026, 1, 2),
            mode: MatchMode.oneVsOne,
            t1p1: 'p0',
            t1p2: '',
            t2p1: 'p3',
            t2p2: '',
            t1Score: 2,
            t2Score: 5,
            winningTeam: 2,
            scorerIds: const [],
          ),
        );
      await tester.runAsync(fixture.matchesRepository.load);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(const PlayerProfileScreen(playerId: 'p3')));
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(
            of: find.byKey(const ValueKey('profile-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('LE MIE STATISTICHE'),
        120,
        scrollable: scrollable,
      );
      expect(find.bySemanticsLabel(RegExp(r'Partite: 1')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Gol: 0')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Non disponibile'),
        200,
        scrollable: scrollable,
      );
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.sports_martial_arts), findsOneWidget);
      expect(find.text('Non disponibile'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-match-legacy')),
        200,
        scrollable: scrollable,
      );
      expect(find.text('Vittoria · 2-5'), findsOneWidget);
      expect(find.text('0 gol'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('landscape content respects lateral system safe areas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(
      left: 44,
      right: 44,
      bottom: 21,
    );
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const PlayerProfileScreen(playerId: 'p3')));
    await tester.pumpAndSettle();
    final scrollable = find.byKey(const ValueKey('profile-scroll'));
    expect(tester.getRect(scrollable).left, greaterThanOrEqualTo(44));
    expect(tester.getRect(scrollable).right, lessThanOrEqualTo(524));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets('large head-to-head metrics wrap without hiding values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const metric = '1234567890123V · 1234567890123P';
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ProfileHeadToHeadRow(
            item: const HeadToHeadStats(
              opponentId: 'p0',
              games: 2469135780246,
              wins: 1234567890123,
              losses: 1234567890123,
            ),
            players: fixture.playersRepository.players,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(metric), findsOneWidget);
    final bounds = tester.getRect(find.text(metric));
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(402));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
