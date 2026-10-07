import 'dart:async';
import 'package:biliardino/cubits/app_style/app_style_cubit.dart';
import 'package:biliardino/cubits/home/home_cubit.dart';
import 'package:biliardino/cubits/data_management/data_management_cubit.dart';
import 'package:biliardino/models/app_style.dart';
import 'package:biliardino/presentation/presentation_host.dart';
import 'package:biliardino/repositories/app_style_repository.dart';
import 'package:biliardino/screens/appearance_screen.dart';
import 'package:biliardino/repositories/data_management_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/design_fixture.dart';
import '../support/controlled_style_fixture.dart';
import '../support/fake_data_management.dart';

class _DataFixture extends DesignFixture {
  final data = FakeData()..barrier = Completer<void>();
  @override
  DataManagementRepository get dataCoordinator => data;
}

Future<BuildContext> _open(WidgetTester tester, DesignFixture fixture) async {
  await tester.pumpWidget(fixture.app);
  await tester.pumpAndSettle();
  final ctx = tester.element(find.byType(PresentationHost));
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
  return ctx;
}

Future<void> _tap(WidgetTester tester, AppStyle style) async {
  final target = find.byKey(ValueKey('appearance-${style.storageValue}'));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void _cleanup(WidgetTester tester, DesignFixture fixture) =>
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await fixture.dispose();
    });
void main() {
  testWidgets(
    'both Altro entries switch in place, back and reopen with committed choice',
    (tester) async {
      _viewport(tester);
      final fixture = DesignFixture();
      await fixture.load();
      _cleanup(tester, fixture);
      final ctx = await _open(tester, fixture);
      final state = tester.state(find.byType(AppearanceScreen));
      final navigator = Navigator.of(ctx);
      final roster = fixture.playersRepository.players;
      expect(find.text('In uso'), findsOneWidget);
      expect(
        find.text('Home'),
        findsNothing,
        reason: 'The pushed selector has no tab bar',
      );
      await _tap(tester, AppStyle.italia90);
      await tester.pumpAndSettle();
      expect(ctx.read<AppStyleCubit>().state, AppStyle.italia90);
      expect(tester.state(find.byType(AppearanceScreen)), same(state));
      expect(
        Navigator.of(tester.element(find.byType(AppearanceScreen))),
        same(navigator),
      );
      expect(fixture.playersRepository.players, roster);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(ctx.read<HomeCubit>().state, HomeDestination.more);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('more-appearance')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('more-appearance')));
      await tester.pumpAndSettle();
      await _tap(tester, AppStyle.southAfrica2010);
      await tester.pumpAndSettle();
      expect(ctx.read<AppStyleCubit>().state, AppStyle.southAfrica2010);
      expect(find.text('In uso'), findsOneWidget);
      final recreated = AppStyleRepository(fixture.database);
      await recreated.load();
      expect(recreated.style, AppStyle.southAfrica2010);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failure retains old choice and retry prevents overlapping taps',
    (tester) async {
      _viewport(tester);
      final db = ControlledStyleDatabase()..fail = true;
      final fixture = ControlledStyleFixture(db);
      await fixture.load();
      _cleanup(tester, fixture);
      final ctx = await _open(tester, fixture);
      await _tap(tester, AppStyle.italia90);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('appearance-error')), findsOneWidget);
      expect(ctx.read<AppStyleCubit>().state, AppStyle.southAfrica2010);
      db.fail = false;
      db.barrier = Completer<void>();
      await _tap(tester, AppStyle.italia90);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('appearance-italia-90')));
      await tester.pump();
      expect(db.writes, 2);
      expect(ctx.read<AppStyleCubit>().state, AppStyle.southAfrica2010);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      db.barrier!.complete();
      await tester.pumpAndSettle();
      expect(ctx.read<AppStyleCubit>().state, AppStyle.italia90);
      expect(find.byKey(const ValueKey('appearance-error')), findsNothing);
      expect(db.settings[AppStyleRepository.storageKey], 'italia-90');
    },
  );
  testWidgets(
    'back during a pending write completes once without updating disposed route',
    (tester) async {
      _viewport(tester);
      final db = ControlledStyleDatabase()..barrier = Completer<void>();
      final fixture = ControlledStyleFixture(db);
      await fixture.load();
      _cleanup(tester, fixture);
      final ctx = await _open(tester, fixture);
      await _tap(tester, AppStyle.italia90);
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(AppearanceScreen), findsNothing);
      await tester.ensureVisible(find.byKey(const ValueKey('more-appearance')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('more-appearance')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byKey(const ValueKey('appearance-italia-90')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('appearance-error')),
        findsNothing,
        reason:
            'Reopening during a healthy pending write must not report a false failure',
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(db.writes, 1);
      db.barrier!.complete();
      await tester.pumpAndSettle();
      expect(db.writes, 1);
      expect(ctx.read<AppStyleCubit>().state, AppStyle.italia90);
      expect(ctx.read<HomeCubit>().state, HomeDestination.more);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'hidden Italia export retains its owner and defers selection until finished',
    (tester) async {
      _viewport(tester);
      final fixture = _DataFixture();
      await fixture.load();
      await fixture.styleRepository.save(AppStyle.italia90);
      _cleanup(tester, fixture);
      await tester.pumpWidget(fixture.app);
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(PresentationHost));
      ctx.read<HomeCubit>().select(HomeDestination.data);
      await tester.pumpAndSettle();
      final exportCtx = tester.element(
        find.byKey(const ValueKey('export-json')),
      );
      // Exercise the actual data screen; the repository controls pending I/O.
      final owner = exportCtx.read<DataManagementCubit>();
      fixture.database.settings['untouched'] = 'value';
      await tester.tap(find.byKey(const ValueKey('export-json')));
      await tester.pump();
      expect(fixture.data.exports, 1);
      expect(owner.state.busy, isTrue);
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
      expect(
        find.byKey(const ValueKey('appearance-data-busy')),
        findsOneWidget,
      );
      await _tap(tester, AppStyle.southAfrica2010);
      await tester.pumpAndSettle();
      expect(ctx.read<AppStyleCubit>().state, AppStyle.italia90);
      fixture.data.barrier!.complete();
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(owner.state.busy, isFalse);
      await _tap(tester, AppStyle.southAfrica2010);
      await tester.pumpAndSettle();
      expect(ctx.read<AppStyleCubit>().state, AppStyle.southAfrica2010);
      expect(fixture.database.settings['untouched'], 'value');
      expect(fixture.data.exports, 1);
      expect(owner.isClosed, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
