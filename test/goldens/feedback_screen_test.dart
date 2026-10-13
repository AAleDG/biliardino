import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/presentation/presentation_host.dart';
import 'package:biliardino/repositories/feedback_repository.dart';
import 'package:biliardino/screens/feedback/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_fixture.dart';

void main() {
  setUpAll(() async {
    await loadDesignFonts();
    for (final entry in {
      'Anton': ['assets/fonts/Anton-Regular.ttf'],
      'Italia Barlow': [
        'assets/fonts/Barlow-Regular.ttf',
        'assets/fonts/Barlow-Bold.ttf',
      ],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final asset in entry.value) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
  });
  for (final style in AppStyle.values) {
    for (final layout in ['reference', 'compact', 'keyboard']) {
      testWidgets('feedback ${style.storageValue} $layout', (tester) async {
        final compact = layout == 'compact';
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
        fixture.feedbackRepository = FeedbackRepository(fixture.database);
        await fixture.load();
        await fixture.styleRepository.save(style);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await fixture.dispose();
        });
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('feedback-capture'),
            child: fixture.app,
          ),
        );
        await tester.pumpAndSettle();
        tester
            .element(find.byType(PresentationHost))
            .read<HomeCubit>()
            .select(HomeDestination.more);
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('more-feedback'));
        await tester.scrollUntilVisible(
          action,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();
        final screen = tester.element(find.byType(FeedbackScreen));
        await tester.runAsync(
          () => precacheImage(
            AssetImage(
              style == AppStyle.italia90
                  ? 'assets/feedback/italia90-backdrop-r2.png'
                  : 'assets/feedback/south-africa-backdrop-r2.png',
            ),
            screen,
          ),
        );
        await tester.pumpAndSettle();
        if (layout == 'keyboard') {
          await tester.ensureVisible(
            find.byKey(const ValueKey('feedback-email')),
          );
          await tester.tap(find.byKey(const ValueKey('feedback-email')));
          tester.view.viewInsets = const FakeViewPadding(bottom: 320);
          await tester.pumpAndSettle();
        }
        final capture = find.byKey(const ValueKey('feedback-capture'));
        await expectLater(
          capture,
          matchesGoldenFile('feedback-${style.storageValue}-$layout.png'),
        );
        if (compact || layout == 'keyboard') {
          final send = find.byKey(const ValueKey('feedback-send'));
          await tester.ensureVisible(send);
          await tester.pumpAndSettle();
          expect(send.hitTestable(), findsOneWidget);
          expect(
            tester.getRect(send).bottom,
            lessThanOrEqualTo(layout == 'keyboard' ? 554 : 568),
          );
          await expectLater(
            capture,
            matchesGoldenFile(
              'feedback-${style.storageValue}-$layout-scrolled.png',
            ),
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
