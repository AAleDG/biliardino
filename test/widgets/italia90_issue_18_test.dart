import 'package:biliardino/cubits/players/players_cubit.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/presentation/app_presentation.dart';
import 'package:biliardino/presentation/italia90/italia90_presentation.dart';
import 'package:biliardino/presentation/italia90/screens/players_screen.dart'
    as italia;
import 'package:biliardino/presentation/italia90/theme/app_theme.dart';
import 'package:biliardino/presentation/italia90/theme/italia90_tokens.dart';
import 'package:biliardino/presentation/italia90/widgets/avatar.dart';
import 'package:biliardino/presentation/italia90/widgets/italia90_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

Future<DesignFixture> _mountPlayers(
  WidgetTester tester, {
  Size size = const Size(402, 874),
  double textScale = 1,
  List<Player>? players,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final fixture = DesignFixture(empty: true);
  fixture.database.players.addAll(
    players ??
        [
          Player(
            id: 'p0',
            name: 'Andrea',
            createdAt: DateTime(2026),
            isPresent: true,
          ),
          Player(
            id: 'p1',
            name: 'Giulia',
            createdAt: DateTime(2026),
            isPresent: false,
          ),
          Player(
            id: 'p2',
            name: 'Luca',
            createdAt: DateTime(2026),
            isPresent: true,
          ),
        ],
  );
  await fixture.load();
  await tester.pumpWidget(
    AppPresentationScope(
      presentation: const Italia90Presentation(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.italia90(),
        home: BlocProvider(
          create: (_) => PlayersCubit(fixture.playersRepository),
          child: const italia.PlayersScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.dispose();
  });
  return fixture;
}

void main() {
  testWidgets('Italia players center summaries and use neutral avatars', (
    tester,
  ) async {
    await _mountPlayers(tester);

    final presentLabel = find.byKey(
      const ValueKey('players-summary-present-label'),
    );
    final readyLabel = find.byKey(
      const ValueKey('players-summary-ready-label'),
    );
    final presentChip = find.ancestor(
      of: presentLabel,
      matching: find.byType(Container),
    );
    final readyChip = find.ancestor(
      of: readyLabel,
      matching: find.byType(Container),
    );

    expect(
      tester.getCenter(presentLabel).dx,
      closeTo(tester.getCenter(presentChip.first).dx, 0.5),
    );
    expect(
      tester.getCenter(presentLabel).dy,
      closeTo(tester.getCenter(presentChip.first).dy, 0.5),
    );
    expect(
      tester.getCenter(readyLabel).dx,
      closeTo(tester.getCenter(readyChip.first).dx, 0.5),
    );
    expect(
      tester.getCenter(readyLabel).dy,
      closeTo(tester.getCenter(readyChip.first).dy, 0.5),
    );
    expect(
      tester
          .getCenter(
            find.byKey(const ValueKey('players-summary-present-number')),
          )
          .dy,
      closeTo(tester.getCenter(presentLabel).dy, 0.5),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('players-summary-present-word')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('players-summary-present-number')),
            )
            .dy,
      ),
    );
    expect(tester.getSize(presentChip.first).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(readyChip.first).height, greaterThanOrEqualTo(48));

    final avatars = tester.widgetList<PlayerAvatar>(find.byType(PlayerAvatar));
    expect(avatars, isNotEmpty);
    expect(
      avatars.every((avatar) => avatar.color == Italia90.avatarNeutral),
      isTrue,
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('player-presence-p0')))
          .properties
          .label,
      'Presenza di Andrea',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Italia action keeps label centered at enlarged text', (
    tester,
  ) async {
    await _mountPlayers(
      tester,
      size: const Size(320, 568),
      textScale: 2,
      players: [
        Player(
          id: 'p0',
          name: 'Giocatore con un nome lungo',
          createdAt: DateTime(2026),
          isPresent: true,
        ),
      ],
    );

    final action = find.byType(FilledButton);
    final label = find.text('NUOVO GIOCATORE');
    expect(action, findsOneWidget);
    expect(tester.getCenter(label).dx, closeTo(tester.getCenter(action).dx, 1));
    expect(tester.getSize(action).shortestSide, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Italia action preserves the busy label and disabled semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.italia90(),
        home: const Scaffold(
          body: Center(
            child: ItaliaAction(
              label: 'SALVA RISULTATO',
              busy: true,
              icon: Icons.save,
              onPressed: null,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final action = find.byType(ItaliaAction);
    final semantics = tester.getSemantics(action);
    expect(
      semantics,
      matchesSemantics(
        label: 'SALVA RISULTATO, in corso',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    expect(
      tester.getSize(find.byType(FilledButton)).shortestSide,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });
}
