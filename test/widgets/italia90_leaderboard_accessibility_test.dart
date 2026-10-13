import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/models/player_badge.dart';
import 'package:biliardino/models/player_stats.dart';
import 'package:biliardino/models/team_leaderboard_stats.dart';
import 'package:biliardino/presentation/italia90/screens/home_screen.dart'
    as italia90;
import 'package:biliardino/presentation/italia90/theme/app_theme.dart';
import 'package:biliardino/presentation/italia90/widgets/design/ranking_podium.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../support/design_fixture.dart';

void main() {
  setUpAll(() async {
    for (final (family, files) in [
      ('Anton', ['assets/fonts/Anton-Regular.ttf']),
      (
        'Italia Barlow',
        ['assets/fonts/Barlow-Regular.ttf', 'assets/fonts/Barlow-Bold.ttf'],
      ),
      ('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    }
  });

  for (var count = 0; count <= 3; count++) {
    testWidgets('Italia podium renders exactly $count entrant actions', (
      tester,
    ) async {
      _setViewport(tester, const Size(402, 874));
      final entries = _entries().take(count).toList(growable: false);
      String? opened;

      await tester.pumpWidget(_podiumApp(entries, onOpen: (id) => opened = id));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('leaderboard-podium')),
        count == 0 ? findsNothing : findsOneWidget,
      );
      for (final entry in entries) {
        final target = find.byKey(ValueKey('leaderboard-podium-${entry.id}'));
        expect(target, findsOneWidget);
        await tester.tap(target);
        expect(opened, entry.openId);
      }
      expect(
        find.byKey(ValueKey('leaderboard-podium-${_entries().last.id}')),
        count == 3 ? findsOneWidget : findsNothing,
      );
    });
  }

  for (final scale in [2.0, 3.0]) {
    testWidgets(
      'Italia podium remains readable and scroll-safe at ${scale}x text',
      (tester) async {
        _setViewport(tester, const Size(320, 700));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final entries = _entries();
        await tester.pumpWidget(_podiumApp(entries));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(const ValueKey('leaderboard-podium'))),
          isNot(Size.zero),
        );
        for (final entry in entries) {
          expect(
            find.byKey(ValueKey('leaderboard-podium-${entry.id}')),
            findsOneWidget,
          );
        }
        expect(find.text('Alessandro Antonio Delgaudio'), findsWidgets);
        expect(find.text('Capoclassifica'), findsWidgets);
      },
    );
  }

  testWidgets('Italia podium exposes profile and recognition semantics', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    _setViewport(tester, const Size(402, 874));
    final entry = _entries().first;

    await tester.pumpWidget(_podiumApp([entry]));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(
        find.byKey(ValueKey('leaderboard-podium-${entry.id}')),
      ),
      isSemantics(
        label:
            'Posizione 1: Alessandro Antonio Delgaudio. 12 pt. '
            'Capoclassifica.',
        hint: 'Apri il profilo',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey('leaderboard-achievements')),
      ),
      isSemantics(
        label: 'Riconoscimenti\nCapoclassifica: Alessandro Antonio Delgaudio',
      ),
    );
    expect(tester.takeException(), isNull);
    semanticsHandle.dispose();
  });

  testWidgets(
    'Italia podium settles immediately when animations are disabled',
    (tester) async {
      _setViewport(tester, const Size(320, 700));
      final entries = _entries();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.italia90(),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: RankingPodium(
                    entries: entries,
                    showArtwork: false,
                    onOpen: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      for (final entry in entries) {
        expect(
          find.byKey(ValueKey('leaderboard-podium-${entry.id}')),
          findsOneWidget,
        );
      }
    },
  );

  for (final scale in [2.0, 3.0]) {
    testWidgets(
      'Italia leaderboard keeps modes, tabs and ledger scrollable at ${scale}x text',
      (tester) async {
        _setViewport(tester, const Size(320, 700));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final fixture = DesignFixture(
          populatedDashboard: true,
          longRoster: true,
        );
        fixture.database.matches.add(
          GameMatch(
            id: 'pair-extra',
            playedAt: DateTime(2026, 9, 9, 18),
            mode: MatchMode.twoVsTwo,
            isRivalry: false,
            t1p1: 'p0',
            t1p2: 'p2',
            t2p1: 'p3',
            t2p2: 'p4',
            t1Score: 6,
            t2Score: 4,
            winningTeam: 1,
            scorerIds: const ['p0', 'p2', 'p0', 'p3', 'p2', 'p4'],
          ),
        );
        await fixture.load();
        await fixture.styleRepository.save(AppStyle.italia90);
        addTearDown(fixture.dispose);

        await tester.pumpWidget(fixture.app);
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(italia90.HomeScreen));
        context.read<HomeCubit>().select(HomeDestination.leaderboard);
        await tester.pumpAndSettle();

        final ranks = context.read<LeaderboardCubit>();
        expect(ranks.state.selectedMode, MatchMode.twoVsTwo);
        expect(
          find.byKey(const ValueKey('leaderboard-mode-selector')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('leaderboard-ledger')),
          findsOneWidget,
        );

        final firstTeam = ranks.state.teamGeneral.first;
        final teamRow = find.byKey(ValueKey('leaderboard-row-${firstTeam.id}'));
        expect(teamRow, findsOneWidget);
        final teamRowRect = tester.getRect(teamRow);
        expect(teamRowRect.left, greaterThanOrEqualTo(0));
        expect(teamRowRect.right, lessThanOrEqualTo(320));
        for (final suffix in ['pg', 'gol', 'v', 'pt']) {
          final metricRect = tester.getRect(
            find.byKey(ValueKey('leaderboard-${firstTeam.id}-$suffix')),
          );
          expect(metricRect.left, greaterThanOrEqualTo(teamRowRect.left));
          expect(metricRect.right, lessThanOrEqualTo(teamRowRect.right));
        }
        final chips = find.byType(Chip);
        for (var i = 0; i < chips.evaluate().length; i++) {
          final chipRect = tester.getRect(chips.at(i));
          expect(chipRect.left, greaterThanOrEqualTo(0));
          expect(chipRect.right, lessThanOrEqualTo(320));
        }

        await tester.tap(find.text('Marcatori'));
        await tester.pumpAndSettle();
        expect(ranks.state.selectedTab, 1);

        await tester.tap(find.text('1vs1'));
        await tester.pumpAndSettle();
        expect(ranks.state.selectedMode, MatchMode.oneVsOne);
        expect(find.text('Alessandro Antonio Delgaudio'), findsWidgets);

        final scroll = find.byKey(const ValueKey('leaderboard-scroll')).first;
        final scrollable = find
            .descendant(of: scroll, matching: find.byType(Scrollable))
            .first;
        expect(
          tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
          greaterThan(0),
        );
        await tester.drag(scroll, const Offset(0, -420));
        await tester.pumpAndSettle();
        final lastPlayer = ranks.state.general.last.player;
        final lastRow = find.byKey(
          ValueKey('leaderboard-row-${lastPlayer.id}'),
        );
        await tester.ensureVisible(lastRow);
        expect(lastRow, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _podiumApp(
  List<RankingPodiumEntry> entries, {
  ValueChanged<String>? onOpen,
}) => MaterialApp(
  theme: AppTheme.italia90(),
  home: Scaffold(
    body: SingleChildScrollView(
      child: RankingPodium(
        entries: entries,
        showArtwork: false,
        onOpen: onOpen ?? (_) {},
      ),
    ),
  ),
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

List<RankingPodiumEntry> _entries() {
  final alex = Player(
    id: 'alex',
    isPresent: true,
    name: 'Alessandro Antonio Delgaudio',
    createdAt: DateTime(2026),
  );
  final beatrice = Player(
    id: 'beatrice',
    isPresent: true,
    name: 'Beatrice Lunghissimo Cognome',
    createdAt: DateTime(2026),
  );
  final giuseppe = Player(
    id: 'giuseppe',
    isPresent: true,
    name: 'Giuseppe Nome Molto Lungo',
    createdAt: DateTime(2026),
  );
  return [
    RankingPodiumEntry.player(
      PlayerStats(
        player: alex,
        games: 4,
        wins: 4,
        losses: 0,
        goalsScored: 12,
        badges: const [
          PlayerBadge(
            code: 'leader',
            label: 'Capoclassifica',
            description: 'Miglior punteggio',
          ),
        ],
      ),
      metric: '12 pt',
    ),
    RankingPodiumEntry.team(
      TeamLeaderboardStats(
        id: 'beatrice-giuseppe',
        players: [beatrice, giuseppe],
        games: 4,
        wins: 3,
        losses: 1,
        goalsScored: 9,
      ),
      metric: '9 pt',
    ),
    RankingPodiumEntry.player(
      PlayerStats(
        player: giuseppe,
        games: 3,
        wins: 2,
        losses: 1,
        goalsScored: 7,
      ),
      metric: '6 pt',
    ),
  ];
}
