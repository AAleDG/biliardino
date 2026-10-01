import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/screens/home_screen.dart';
import 'package:biliardino/screens/more_screen.dart';
import 'package:biliardino/widgets/design/pass_artwork.dart';
import 'package:biliardino/widgets/design/foosball_scene.dart';
import '../support/design_fixture.dart';

void main() {
  setUpAll(loadDesignFonts);
  for (final spec in [
    ('reference', const Size(402, 874), 1.0),
    ('compact', const Size(320, 568), 2.0),
    ('landscape', const Size(568, 320), 2.0),
  ]) {
    testWidgets('Pass integrated ${spec.$1}', (tester) async {
      tester.view.physicalSize = spec.$2;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = spec.$1 == 'landscape'
          ? const FakeViewPadding(left: 44, right: 44, bottom: 24)
          : const FakeViewPadding(top: 62, bottom: 34);
      tester.view.viewPadding = tester.view.padding;
      tester.platformDispatcher.textScaleFactorTestValue = spec.$3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = DesignFixture();
      await fixture.load();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await fixture.dispose();
      });
      await tester.pumpWidget(
        RepaintBoundary(key: const ValueKey('capture'), child: fixture.home),
      );
      final context = tester.element(find.byType(HomeScreen));
      await tester.runAsync(
        () => precacheImage(const AssetImage(FoosballScene.asset), context),
      );
      context.read<HomeCubit>().select(HomeDestination.more);
      await tester.pumpAndSettle();
      Future<void> capture(String screen) async {
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile('pass-$screen-${spec.$1}.png'),
        );
      }

      final data = find.byKey(const ValueKey('more-data'));
      final heading = find.text('ALTRO');
      final footer = find.descendant(
        of: find.byType(MoreScreen),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.painter is PassRibbons &&
              (widget.painter! as PassRibbons).kind == PassRibbonKind.footer,
        ),
      );
      expect(
        footer,
        findsOneWidget,
        reason: 'Altro footer remains visible even when the cards overflow',
      );
      await capture('more');
      final headingBefore = tester.getRect(heading);
      final footerBefore = tester.getRect(footer);
      final dataBefore = tester.getTopLeft(data);
      await Scrollable.ensureVisible(tester.element(data), alignment: .5);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(heading),
        headingBefore,
        reason: 'Altro heading stays fixed while its cards scroll',
      );
      expect(
        tester.getRect(footer),
        footerBefore,
        reason: 'Altro footer stays fixed above the tab bar',
      );
      expect(data.hitTestable(), findsOneWidget);
      if (spec.$3 == 2) {
        expect(tester.getTopLeft(data).dy, lessThan(dataBefore.dy));
        await capture('more-scrolled');
      }
      await tester.tap(data);
      await tester.pumpAndSettle();
      await capture('data');
      await tester.ensureVisible(find.byKey(const ValueKey('restore-json')));
      await tester.pumpAndSettle();
      if (spec.$3 == 2) await capture('data-scrolled');
    });
  }
}
