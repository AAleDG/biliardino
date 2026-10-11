import 'dart:convert';
import 'dart:io';
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/leaderboard/leaderboard_cubit.dart';
import 'package:biliardino/cubits/new_match/new_match_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/match_rules.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/navigation/app_navigation.dart';
import 'package:biliardino/presentation/italia90/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../support/design_fixture.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it');
    for (final item in {
      'Anton': ['assets/fonts/Anton-Regular.ttf'],
      'Italia Barlow': [
        'assets/fonts/Barlow-Regular.ttf',
        'assets/fonts/Barlow-Bold.ttf',
      ],
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
    }.entries) {
      final loader = FontLoader(item.key);
      for (final file in item.value) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    }
  });
  final references =
      jsonDecode(
            File(
              'test/goldens/italia90-reference/provenance.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  for (final reference in references['references'] as List) {
    final name = reference['name'] as String;
    // Issue 17 intentionally replaces the live composition; donor PNGs stay frozen.
    final isLiveScoreAcceptance = name.startsWith('core-live-');
    final testTitle = isLiveScoreAcceptance
        ? 'Italia live-score acceptance'
        : 'Italia donor parity';
    testWidgets('$testTitle: $name', (tester) async {
      final metadata =
          jsonDecode(
                File(
                  'test/goldens/italia90-reference/$name.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final viewport = metadata['viewport'] as Map;
      final safe = metadata['safe_area'] as Map;
      tester.view.physicalSize = Size(
        (viewport['width'] as num).toDouble(),
        (viewport['height'] as num).toDouble(),
      );
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(
        top: (safe['top'] as num).toDouble(),
        bottom: (safe['bottom'] as num).toDouble(),
      );
      tester.platformDispatcher.textScaleFactorTestValue =
          name == 'flows-setup-large'
          ? 1
          : (metadata['text_scale'] as num).toDouble();
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final shadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = shadows);
      final fixture = DesignFixture(empty: true);
      fixture.database.players.addAll(
        (metadata['players'] as List).map(
          (p) => Player.fromMap(Map<String, dynamic>.from(p as Map)),
        ),
      );
      fixture.database.matches.addAll(
        (metadata['matches'] as List).map(
          (m) => GameMatch.fromMap(Map<String, dynamic>.from(m as Map)),
        ),
      );
      await fixture.load();
      await fixture.styleRepository.save(AppStyle.italia90);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: key, child: fixture.app));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(HomeScreen));
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/italia90/backdrop-proposal-2.png'),
          ctx,
        ),
      );
      if (isLiveScoreAcceptance) {
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/italia90/live-poster-editoriale.png'),
            ctx,
          ),
        );
      }
      await tester.pumpAndSettle();
      final home = ctx.read<HomeCubit>();
      final match = ctx.read<NewMatchCubit>();
      final setup = metadata['match_setup'] as Map;
      match.setMatchMode(MatchMode.values.byName(setup['mode'] as String));
      for (final entry in (setup['assignment'] as Map).entries) {
        match.setTeam(entry.key as String, entry.value as int);
      }
      final rules = setup['rules'] as Map;
      await match.setRuleMode(
        MatchRuleMode.values.byName(rules['mode'] as String),
      );
      await match.setTargetScore(rules['target_score'] as int);
      await match.setWinByTwo(rules['win_by_two'] as bool);
      match.setRivalry(setup['is_rivalry'] as bool);
      if (setup['kicked_off'] == true) {
        match.kickoff();
        for (final id in setup['scorer_ids'] as List) {
          match.addGoal(match.state.team1.contains(id) ? 1 : 2, id as String);
        }
      }
      final ranks = ctx.read<LeaderboardCubit>();
      ranks.selectMode(
        MatchMode.values.byName(metadata['leaderboard_mode'] as String),
      );
      home.select(
        HomeDestination.values.byName(metadata['destination'] as String),
      );
      await tester.pumpAndSettle();
      if (name.endsWith('-scorers') || name == 'flows-standings-large') {
        ranks.selectTab(1);
        await tester.pumpAndSettle();
      }
      if (name.contains('pair-profile')) {
        final id = ranks.state.teamGeneral
            .firstWhere((pair) => pair.name == 'Andrea + Luca')
            .id;
        openPairProfile(ctx, id);
        await tester.pumpAndSettle();
        if (name.endsWith('-history')) {
          await tester.scrollUntilVisible(
            find.text('PARTITE INSIEME'),
            250,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
        }
      } else if (name.contains('-profile')) {
        openPlayerProfile(
          ctx,
          name.endsWith('-missing') ? 'missing' : 'Andrea',
        );
        await tester.pumpAndSettle();
        if (name.endsWith('-history')) {
          await tester.scrollUntilVisible(
            find.text('STORICO PERSONALE'),
            250,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
        }
      } else if (name.endsWith('-history-filters')) {
        await tester.tap(find.byKey(const ValueKey('history-open-filters')));
        await tester.pumpAndSettle();
      } else if (name.endsWith('-history-detail') ||
          name.endsWith('-history-edit')) {
        await tester.tap(find.byKey(const ValueKey('history-match-preview-5')));
        await tester.pumpAndSettle();
        if (name.endsWith('-history-edit')) {
          await tester.tap(find.byKey(const ValueKey('match-details-edit')));
          await tester.pumpAndSettle();
        }
      } else if (name.endsWith('-setup-final-player')) {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('present-player-Paolo')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }
      if (name == 'flows-setup-large') {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('present-player-Paolo')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      boundary.reassemble();
      await tester.pump();
      final image = await tester.runAsync(
        () => boundary.toImage(pixelRatio: 2),
      );
      try {
        await expectLater(
          image,
          matchesGoldenFile(
            name.startsWith('supplement-more-')
                ? 'appearance-altro-$name.png'
                : isLiveScoreAcceptance
                ? 'italia90-issue-17-reference/$name.png'
                : 'italia90-reference/${reference['corrected_expected'] ?? '$name.png'}',
          ),
        );
      } finally {
        image!.dispose();
        debugDisableShadows = shadows;
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
  }
}
