import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/models/ranking_stats.dart';
import 'package:biliardino/presentation/italia90/screens/leaderboard_screen.dart';
import 'package:biliardino/presentation/italia90/theme/app_theme.dart';
import 'package:biliardino/repositories/match_repository.dart';
import 'package:biliardino/repositories/player_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';
import '../support/fake_database.dart';

void main() {
  setUpAll(loadDesignFonts);

  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets(
      'Italia leaderboard keeps every recognition live at ${scale}x text',
      (tester) async {
        final fixture = await tester.runAsync(_ItaliaLeaderboardFixture.create);
        final liveFixture = fixture!;
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(liveFixture.dispose);
        });

        _configureViewport(tester, textScale: scale);
        await tester.pumpWidget(liveFixture.widget());
        await _pumpScreen(tester);

        final completePairs = liveFixture.cubit.state.teamGeneral;
        expect(completePairs, hasLength(4));
        expect(
          completePairs.expand((pair) => pair.badges),
          hasLength(8),
          reason: 'The tie fixture must award two badges to each pair.',
        );
        _expectRecognitions(tester, completePairs);
        final fourthPair = completePairs[3];
        expect(fourthPair.badges, isNotEmpty);
        final fourthRecognition = find.byKey(
          ValueKey(
            'leaderboard-achievement-${fourthPair.id}-'
            '${fourthPair.badges.first.code}',
          ),
        );
        expect(fourthRecognition, findsOneWidget);
        expect(
          find.byKey(ValueKey('leaderboard-podium-${fourthPair.id}')),
          findsNothing,
          reason: 'The fourth pair must stay out of the three-place podium.',
        );
        final leaderboardScroll = find
            .descendant(
              of: find.byKey(const ValueKey('leaderboard-scroll')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          fourthRecognition,
          500,
          scrollable: leaderboardScroll,
        );
        await tester.pump();
        final fourthRect = tester.getRect(fourthRecognition);
        expect(
          fourthRect.top,
          lessThan(874),
          reason:
              'The fourth recognition must remain reachable after scrolling.',
        );
        expect(fourthRect.bottom, greaterThan(0));
        expect(fourthRecognition.hitTestable(), findsOneWidget);
        expect(
          find.byKey(const ValueKey('leaderboard-achievements')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('leaderboard-podium')),
            matching: find.byKey(const ValueKey('leaderboard-achievements')),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Marcatori'));
        await _pumpScreen(tester);
        _expectRecognitions(tester, completePairs);
        expect(fourthRecognition, findsOneWidget);
        final leaderboardScrollAfterTab = find
            .descendant(
              of: find.byKey(const ValueKey('leaderboard-scroll')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          fourthRecognition,
          500,
          scrollable: leaderboardScrollAfterTab,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('1vs1'));
        await _pumpScreen(tester);
        _expectRecognitions(tester, liveFixture.cubit.state.general);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Italia leaderboard exposes recipient and explanation to semantics',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      final fixture = await tester.runAsync(_ItaliaLeaderboardFixture.create);
      final liveFixture = fixture!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(liveFixture.dispose);
      });

      try {
        _configureViewport(tester, textScale: 2);
        await tester.pumpWidget(liveFixture.widget());
        await _pumpScreen(tester);

        final pair = liveFixture.cubit.state.teamGeneral.firstWhere(
          (stats) => stats.name == 'Marco + Paolo',
        );
        const badgeCode = 'leader';
        final badge = pair.badges.firstWhere((item) => item.code == badgeCode);
        final label = '${badge.label}: ${pair.name}. ${badge.description}';
        final recognition = find.byKey(
          ValueKey('leaderboard-achievement-${pair.id}-$badgeCode'),
        );
        expect(recognition, findsOneWidget);
        await tester.ensureVisible(recognition);
        await tester.pump();

        expect(find.bySemanticsLabel(label), findsOneWidget);
        expect(find.text(pair.name), findsWidgets);
        expect(
          find.descendant(
            of: recognition,
            matching: find.text(badge.description),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semanticsHandle.dispose();
      }
    },
  );
}

void _configureViewport(WidgetTester tester, {required double textScale}) {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void _expectRecognitions(WidgetTester tester, Iterable<RankingStats> entries) {
  for (final entry in entries) {
    for (final badge in entry.badges) {
      expect(
        find.byKey(
          ValueKey('leaderboard-achievement-${entry.id}-${badge.code}'),
        ),
        findsOneWidget,
      );
      expect(find.text(badge.label), findsWidgets);
      expect(find.text(entry.name), findsWidgets);
      expect(find.text(badge.description), findsWidgets);
    }
  }
}

class _ItaliaLeaderboardFixture {
  _ItaliaLeaderboardFixture({
    required this.playerRepository,
    required this.matchRepository,
    required this.cubit,
  });

  final PlayerRepository playerRepository;
  final MatchRepository matchRepository;
  final LeaderboardCubit cubit;

  static Future<_ItaliaLeaderboardFixture> create() async {
    final database = FakeDatabaseHelper(players: _players, matches: _matches);
    final playerRepository = PlayerRepository(database);
    final matchRepository = MatchRepository(database);
    await Future.wait([playerRepository.load(), matchRepository.load()]);
    final cubit = LeaderboardCubit(
      playerRepository: playerRepository,
      matchRepository: matchRepository,
    );
    return _ItaliaLeaderboardFixture(
      playerRepository: playerRepository,
      matchRepository: matchRepository,
      cubit: cubit,
    );
  }

  Widget widget() => MaterialApp(
    theme: AppTheme.italia90(),
    home: BlocProvider.value(value: cubit, child: const LeaderboardScreen()),
  );

  Future<void> dispose() async {
    await cubit.close();
    await playerRepository.dispose();
    await matchRepository.dispose();
  }
}

final _players = [
  for (final name in [
    'Marco',
    'Paolo',
    'Andrea',
    'Luca',
    'Giulia',
    'Sara',
    'Elena',
    'Fabio',
  ])
    Player(id: name, name: name, createdAt: DateTime(2026), isPresent: true),
];

final _matches = [
  _twoVsTwoMatch(
    id: 'pairs-marco',
    team1: const ['Marco', 'Paolo'],
    team2: const ['Andrea', 'Luca'],
    scorer1: 'Marco',
    scorer2: 'Andrea',
  ),
  _twoVsTwoMatch(
    id: 'pairs-giulia',
    team1: const ['Giulia', 'Sara'],
    team2: const ['Elena', 'Fabio'],
    scorer1: 'Giulia',
    scorer2: 'Elena',
  ),
  _twoVsTwoMatch(
    id: 'pairs-andrea',
    team1: const ['Andrea', 'Luca'],
    team2: const ['Giulia', 'Sara'],
    scorer1: 'Andrea',
    scorer2: 'Giulia',
  ),
  _twoVsTwoMatch(
    id: 'pairs-elena',
    team1: const ['Elena', 'Fabio'],
    team2: const ['Marco', 'Paolo'],
    scorer1: 'Elena',
    scorer2: 'Marco',
  ),
  _oneVsOneMatch(id: 'singles-marco', winner: 'Marco', loser: 'Paolo'),
  _oneVsOneMatch(id: 'singles-giulia', winner: 'Giulia', loser: 'Sara'),
];

GameMatch _twoVsTwoMatch({
  required String id,
  required List<String> team1,
  required List<String> team2,
  required String scorer1,
  required String scorer2,
}) => GameMatch(
  id: id,
  playedAt: DateTime(2026, 1, 1),
  mode: MatchMode.twoVsTwo,
  isRivalry: false,
  t1p1: team1[0],
  t1p2: team1[1],
  t2p1: team2[0],
  t2p2: team2[1],
  t1Score: 5,
  t2Score: 3,
  winningTeam: 1,
  scorerIds: [...List.filled(5, scorer1), ...List.filled(3, scorer2)],
);

GameMatch _oneVsOneMatch({
  required String id,
  required String winner,
  required String loser,
}) => GameMatch(
  id: id,
  playedAt: DateTime(2026, 1, 2),
  mode: MatchMode.oneVsOne,
  isRivalry: false,
  t1p1: winner,
  t1p2: '',
  t2p1: loser,
  t2p2: '',
  t1Score: 5,
  t2Score: 3,
  winningTeam: 1,
  scorerIds: [...List.filled(5, winner), ...List.filled(3, loser)],
);
