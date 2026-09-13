import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/navigation/app_navigation.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/screens/match_editor/match_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'design_fixture.dart';
import 'history_design_fixture.dart';

Future<DesignFixture> pumpDistinta(
  WidgetTester tester, {
  Size size = const Size(402, 874),
  double scale = 1,
  bool longNames = false,
  bool legacy = false,
  bool details = false,
  Future<void> Function(GameMatch)? onSave,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = size.width > size.height
      ? const FakeViewPadding(left: 44, right: 44, bottom: 24)
      : const FakeViewPadding(top: 62, bottom: 34);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final fixture = historyDesignFixture(count: 1, longNames: longNames);
  if (legacy) {
    fixture.database.matches[0] = fixture.database.matches[0].copyWith(
      mode: MatchMode.oneVsOne,
      t1p2: '',
      t2p2: '',
      scorerIds: [],
    );
  }
  await fixture.load();
  await tester.pumpWidget(
    RepaintBoundary(key: const ValueKey('editor-capture'), child: fixture.home),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.dispose();
  });
  await tester.pumpAndSettle();
  if (onSave != null) {
    Navigator.of(tester.element(find.byType(HomeScreen))).push<void>(
      MaterialPageRoute(
        builder: (_) => MatchEditorScreen(
          match: fixture.matchesRepository.matches.single,
          players: fixture.playersRepository.players,
          onSave: onSave,
        ),
      ),
    );
  } else {
    openHistory(tester.element(find.byType(HomeScreen)));
    await tester.pumpAndSettle();
    if (details) {
      await tester.tap(find.byKey(const ValueKey('history-match-history-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match-details-edit')));
    } else {
      await tester.tap(find.byTooltip('Azioni partita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Correggi'));
    }
  }
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return fixture;
}

Future<void> editorTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
