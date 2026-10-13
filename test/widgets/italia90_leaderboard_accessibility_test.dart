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
import 'package:biliardino/presentation/italia90/widgets/design/ranking_metrics.dart';
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
          final metric = find.byKey(
            ValueKey('leaderboard-${firstTeam.id}-$suffix'),
          );
          final metricRect = tester.getRect(metric);
          expect(metricRect.left, greaterThanOrEqualTo(teamRowRect.left));
          expect(metricRect.right, lessThanOrEqualTo(teamRowRect.right));
          expect(
            find.ancestor(of: metric, matching: find.byType(FittedBox)),
            findsNothing,
          );
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

        final firstPlayer = ranks.state.general.first.player;
        for (final suffix in ['pg', 'gol', 'v', 'pt']) {
          final metric = find.byKey(
            ValueKey('leaderboard-${firstPlayer.id}-$suffix'),
          );
          expect(metric, findsOneWidget);
          expect(
            find.ancestor(of: metric, matching: find.byType(FittedBox)),
            findsNothing,
          );
        }

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

  testWidgets(
    'Italia leaderboard scrolls its header controls at 200% text in landscape',
    (tester) async {
      _setViewport(tester, const Size(844, 390));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final fixture = DesignFixture(populatedDashboard: true, longRoster: true);
      await fixture.load();
      await fixture.styleRepository.save(AppStyle.italia90);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(italia90.HomeScreen));
      context.read<HomeCubit>().select(HomeDestination.leaderboard);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('leaderboard-shell-scroll')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final tabs = find.text('Marcatori');
      await tester.ensureVisible(tabs);
      await tester.pumpAndSettle();
      final tabRect = tester.getRect(tabs);
      expect(tabRect.top, greaterThanOrEqualTo(0));
      expect(tabRect.bottom, lessThanOrEqualTo(390));

      final modeSelector = find.byKey(
        const ValueKey('leaderboard-mode-selector'),
      );
      await tester.ensureVisible(modeSelector);
      await tester.pumpAndSettle();
      final modeRect = tester.getRect(modeSelector);
      expect(modeRect.top, greaterThanOrEqualTo(0));
      expect(modeRect.bottom, lessThanOrEqualTo(390));

      final ranks = context.read<LeaderboardCubit>();
      await tester.tap(find.text('1vs1'));
      await tester.pumpAndSettle();
      expect(ranks.state.selectedMode, MatchMode.oneVsOne);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ranking metrics keep the requested scale and reflow on narrow screens',
    (tester) async {
      _setViewport(tester, const Size(320, 700));
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.italia90(),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(14),
              child: RankingMetrics(
                id: 'large-text',
                metrics: [
                  RankingMetricSpec(keySuffix: 'pg', label: 'PG', value: '100'),
                  RankingMetricSpec(
                    keySuffix: 'gol',
                    label: 'GOL',
                    value: '200',
                  ),
                  RankingMetricSpec(keySuffix: 'v', label: 'V', value: '99'),
                  RankingMetricSpec(
                    keySuffix: 'pt',
                    label: 'PT',
                    value: '303',
                    emphasized: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final points = find.byKey(const ValueKey('leaderboard-large-text-pt'));
      expect(points, findsOneWidget);
      expect(
        find.ancestor(of: points, matching: find.byType(FittedBox)),
        findsNothing,
      );
      expect(find.text('303'), findsOneWidget);
      final pointsRect = tester.getRect(points);
      expect(pointsRect.left, greaterThanOrEqualTo(0));
      expect(pointsRect.right, lessThanOrEqualTo(320));
    },
  );
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
