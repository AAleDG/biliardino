import 'dart:io';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/screens/pair_profile_screen.dart';
import 'package:biliardino/screens/player_profile_screen.dart';
import 'package:biliardino/screens/leaderboard/ranking_row.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/models/player_stats.dart';
import 'package:biliardino/theme/app_theme.dart';
import 'package:biliardino/services/csv_share_service.dart';
import 'package:biliardino/services/leaderboard_csv_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:share_plus/share_plus.dart';
import '../support/leaderboard_fixture.dart';
import '../support/design_fixture.dart';

void main() {
  setUpAll(() async {
    await loadDesignFonts();
    await initializeDateFormatting('it_IT');
  });
  Future<void> mount(
    WidgetTester tester,
    LeaderboardFixture f, {
    CsvShareService? share,
  }) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(f.load);
    await tester.pumpWidget(f.app(share: share));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(f.dispose);
    });
  }

  for (var count = 0; count <= 3; count++) {
    testWidgets(
      '$count entrants retain exactly their actions and sparse podium blocks in both modes',
      (tester) async {
        final f = LeaderboardFixture(count: count);
        await mount(tester, f);
        for (final tab in ['Generale', 'Marcatori']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          for (var rank = 1; rank <= 3; rank++) {
            expect(
              find.byKey(ValueKey('podium-block-$rank')),
              count == 0 ? findsNothing : findsOneWidget,
            );
          }
          for (var i = 0; i < count; i++) {
            final target = find.byKey(ValueKey('leaderboard-podium-p$i'));
            expect(target, findsOneWidget);
            expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
          }
          expect(
            find.byKey(ValueKey('leaderboard-podium-p$count')),
            findsNothing,
          );
          final export = tester.widget<IconButton>(
            find.byKey(const ValueKey('leaderboard-export-csv')),
          );
          expect(export.onPressed == null, count == 0);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
  testWidgets(
    'both rankings open every podium and remainder profile; active tab survives rename',
    (tester) async {
      final f = LeaderboardFixture();
      await mount(tester, f);
      for (final tab in ['Generale', 'Marcatori']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        final ranking = tab == 'Generale'
            ? f.cubit.state.general
            : f.cubit.state.scorers;
        for (var i = 0; i < ranking.length; i++) {
          final id = ranking[i].player.id;
          final key = ValueKey('leaderboard-${i < 3 ? 'podium' : 'row'}-$id');
          await tester.ensureVisible(find.byKey(key));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(key));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<PlayerProfileScreen>(find.byType(PlayerProfileScreen))
                .playerId,
            id,
          );
          final context = tester.element(find.byType(PlayerProfileScreen));
          Navigator.of(context).pop();
          await tester.pumpAndSettle();
        }
      }
      await tester.runAsync(() async {
        final changed = f.cubit.stream.first;
        await f.playersRepository.renamePlayer(
          f.playersRepository.players.first,
          'Renamed',
        );
        await changed;
      });
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('leaderboard-podium-p0')),
        -250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Renamed'), findsOneWidget);
      expect(find.text('2 gol'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('wide ranking metrics reflow without squeezing the name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.southAfrica(),
        home: Scaffold(
          body: RankingRow(
            rank: 999,
            stats: PlayerStats(
              player: Player(
                id: 'p',
                name: 'Alessandro Antonio Delgaudio',
                createdAt: DateTime(2026),
                isPresent: true,
              ),
              games: 0,
              wins: 0,
              losses: 0,
              goalsScored: 0,
            ),
            metric: '12345678901234567890 gol',
            detail: 'Many games',
            onOpen: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alessandro Antonio Delgaudio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('tabs grow at largest text and remain selectable', (
    tester,
  ) async {
    final f = LeaderboardFixture();
    await mount(tester, f);
    tester.platformDispatcher.textScaleFactorTestValue = 3.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    final tab = find
        .ancestor(of: find.text('Generale'), matching: find.byType(InkWell))
        .first;
    expect(tester.getSize(tab).height, greaterThan(70));
    await tester.ensureVisible(find.text('Marcatori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcatori'));
    await tester.pumpAndSettle();
    expect(find.text('2 gol'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'pair mode renders pairs, opens both profile targets and exports general pairs from Marcatori',
    (tester) async {
      final f = LeaderboardFixture(count: 4, mode: MatchMode.twoVsTwo);
      f.database.matches[1] = f.database.matches[1].copyWith(
        scorerIds: const [],
      );
      final share = _RecordingShare();
      await mount(tester, f, share: share);
      final first = f.cubit.state.teamGeneral.first;
      expect(find.text(first.name), findsWidgets);
      await tester.tap(find.text('Marcatori'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('leaderboard-export-csv')));
      await tester.pumpAndSettle();
      expect(share.content!.split('\n'), hasLength(5));
      expect(share.content, contains('"Coppia"'));
      expect(share.content, contains('"Ale + Luca"'));
      expect(share.content, contains('"Eva + Leo"'));
      expect(f.cubit.state.teamScorers, hasLength(2));
      await tester.tap(find.text('1vs1'));
      await tester.pumpAndSettle();
      expect(find.text('Nessun marcatore disponibile'), findsOneWidget);
      await tester.tap(find.text('2vs2'));
      await tester.pumpAndSettle();
      expect(find.text('Marcatori'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('leaderboard-podium-${first.id}')));
      await tester.pumpAndSettle();
      expect(find.byType(PairProfileScreen), findsOneWidget);
      for (final member in first.players) {
        await tester.ensureVisible(
          find.byKey(ValueKey('pair-member-${member.id}')),
        );
        await tester.tap(find.byKey(ValueKey('pair-member-${member.id}')));
        await tester.pumpAndSettle();
        expect(find.byType(PlayerProfileScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generale'));
      await tester.pumpAndSettle();
      final last = f.cubit.state.teamGeneral.last;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('leaderboard-row-${last.id}')),
        -150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(ValueKey('leaderboard-row-${last.id}')));
      await tester.pumpAndSettle();
      expect(find.byType(PairProfileScreen), findsOneWidget);
      expect(find.text(last.name), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'CSV always shares general ranking, including empty scorers; reports success and failure',
    (tester) async {
      final f = LeaderboardFixture(legacy: true);
      final share = _RecordingShare();
      await mount(tester, f, share: share);
      await tester.tap(find.text('Marcatori'));
      await tester.pumpAndSettle();
      expect(find.text('Nessun marcatore disponibile'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('leaderboard-export-csv')));
      await tester.pumpAndSettle();
      expect(share.content, LeaderboardCsvService.build(f.cubit.state.general));
      expect(share.origin!.width, greaterThan(0));
      expect(find.text('CSV pronto per la condivisione.'), findsOneWidget);
      share.fail = true;
      await tester.tap(find.byKey(const ValueKey('leaderboard-export-csv')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Impossibile esportare il CSV:'),
        findsOneWidget,
      );
    },
  );
}

class _RecordingShare extends CsvShareService {
  _RecordingShare()
    : super(
        temporaryDirectory: () async => Directory.systemTemp,
        shareLauncher: (_) async =>
            const ShareResult('test', ShareResultStatus.success),
      );
  String? content;
  Rect? origin;
  bool fail = false;
  @override
  Future<File> shareCsv({
    required String csv,
    required String fileName,
    required String subject,
    required String text,
    required Rect? sharePositionOrigin,
  }) async {
    content = csv;
    origin = sharePositionOrigin;
    if (fail) throw StateError('share unavailable');
    return File(fileName);
  }
}
