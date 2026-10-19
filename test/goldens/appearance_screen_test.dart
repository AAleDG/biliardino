import 'dart:async';
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/presentation/presentation_host.dart';
import 'package:biliardino/presentation/italia90/widgets/italia_graphic_backdrop.dart';
import 'package:biliardino/screens/appearance_screen.dart';
import 'package:biliardino/screens/dashboard_screen.dart'
    show homeHeroAssetPath;
import 'package:biliardino/widgets/design/foosball_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';
import '../support/controlled_style_fixture.dart';

void main() {
  const paletteRevisionGoldenRoot = 'italia90-palette-2026-reference';
  setUpAll(() async {
    await loadDesignFonts();
    for (final e in {
      'Anton': ['assets/fonts/Anton-Regular.ttf'],
      'Italia Barlow': [
        'assets/fonts/Barlow-Regular.ttf',
        'assets/fonts/Barlow-Bold.ttf',
      ],
    }.entries) {
      final loader = FontLoader(e.key);
      for (final file in e.value) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    }
  });
  for (final style in AppStyle.values) {
    for (final compact in [false, true]) {
      final name =
          'appearance-${style.storageValue}-${compact ? 'compact' : 'reference'}';
      testWidgets(name, (tester) async {
        tester.view.physicalSize = compact
            ? const Size(320, 568)
            : const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
        tester.view.viewPadding = tester.view.padding;
        tester.platformDispatcher.textScaleFactorTestValue = compact ? 2 : 1;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixture = DesignFixture();
        await fixture.load();
        await fixture.styleRepository.save(style);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await fixture.dispose();
        });
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('appearance-capture'),
            child: fixture.app,
          ),
        );
        await tester.pumpAndSettle();
        final ctx = tester.element(find.byType(PresentationHost));
        await tester.runAsync(() async {
          await precacheImage(const AssetImage(homeHeroAssetPath), ctx);
          await precacheImage(const AssetImage(FoosballScene.asset), ctx);
          await precacheImage(
            const AssetImage(
              'assets/italia90/backdrop-working-petrol-amaranto.png',
            ),
            ctx,
          );
        });
        ctx.read<HomeCubit>().select(HomeDestination.more);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('more-appearance')),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('more-appearance')));
        await tester.pumpAndSettle();
        expect(find.byType(AppearanceScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (style == AppStyle.southAfrica2010) {
          expect(
            tester
                .getRect(find.byKey(const ValueKey('appearance-fixed-footer')))
                .bottom,
            tester.view.physicalSize.height,
            reason:
                'Decorative footer reaches the screen edge below the safe area',
          );
        }
        final goldenPath = style == AppStyle.italia90
            ? '$paletteRevisionGoldenRoot/$name.png'
            : '$name.png';
        final back = find.byTooltip('Back');
        expect(back.hitTestable(), findsOneWidget);
        expect(tester.getRect(back).top, greaterThanOrEqualTo(62));
        await expectLater(
          find.byKey(const ValueKey('appearance-capture')),
          matchesGoldenFile(goldenPath),
        );
        if (compact) {
          final footer = style == AppStyle.southAfrica2010
              ? find.byKey(const ValueKey('appearance-fixed-footer'))
              : find.byType(ItaliaGraphicBackdrop);
          final before = tester.getRect(footer);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('appearance-italia-90')),
            200,
            scrollable: find.descendant(
              of: find.byKey(const ValueKey('appearance-scroll')),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('appearance-italia-90')).hitTestable(),
            findsOneWidget,
          );
          expect(tester.getRect(footer), before);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('appearance-capture')),
            matchesGoldenFile(
              style == AppStyle.italia90
                  ? '$paletteRevisionGoldenRoot/$name-scrolled.png'
                  : '$name-scrolled.png',
            ),
          );
        }
      });
    }
  }
  testWidgets('appearance pending write and recoverable error', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    tester.view.viewPadding = tester.view.padding;
    addTearDown(tester.view.reset);
    final db = ControlledStyleDatabase()
      ..barrier = Completer<void>()
      ..fail = true;
    final fixture = ControlledStyleFixture(db);
    await fixture.load();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('appearance-capture'),
        child: fixture.app,
      ),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(PresentationHost));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage(homeHeroAssetPath), ctx);
      await precacheImage(const AssetImage(FoosballScene.asset), ctx);
    });
    ctx.read<HomeCubit>().select(HomeDestination.more);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('more-appearance')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('more-appearance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('appearance-italia-90')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await expectLater(
      find.byKey(const ValueKey('appearance-capture')),
      matchesGoldenFile('appearance-pending.png'),
    );
    db.barrier!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('appearance-error')), findsOneWidget);
    await expectLater(
      find.byKey(const ValueKey('appearance-capture')),
      matchesGoldenFile('appearance-error.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
