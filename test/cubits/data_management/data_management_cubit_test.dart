import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:biliardino/cubits/data_management/data_management_cubit.dart';
import '../../support/fake_data_management.dart';

void main() {
  late FakeData data;
  late DataManagementCubit cubit;
  setUp(() {
    data = FakeData();
    cubit = DataManagementCubit(data);
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });
  int prepare() {
    cubit.restore();
    cubit.picked(cubit.state.effect!.id, '{}');
    return cubit.state.effect!.id;
  }

  test('busy covers picker and ignores repeat intents and stale results', () {
    cubit.restore();
    final id = cubit.state.effect!.id;
    expect(cubit.state.busy, isTrue);
    cubit.restore();
    expect(cubit.state.effect!.id, id);
    cubit.picked(id + 1, '{}');
    expect(cubit.state.effect!.kind, DataEffectKind.pick);
    cubit.picked(id, null);
    expect(cubit.state.busy, isFalse);
    cubit.picked(id, '{}');
    expect(cubit.state.effect, isNull);
    expect(data.writes, 0);
  });
  test('picker and validation failures leave no pending write', () {
    cubit.restore();
    cubit.picked(cubit.state.effect!.id, null, failed: true);
    expect(cubit.state.effect!.message, contains('aprire'));
    cubit.restore();
    cubit.picked(cubit.state.effect!.id, 'bad');
    expect(cubit.state.effect!.message, contains('non valido'));
    expect(cubit.state.busy, isFalse);
    expect(data.writes, 0);
  });
  test('confirmation cancel leaves storage untouched', () async {
    final id = prepare();
    await cubit.confirmed(id, false);
    expect(data.writes, 0);
    expect(cubit.state.busy, isFalse);
    await cubit.confirmed(id, true);
    expect(data.writes, 0);
  });
  test('confirmed restore writes once and refreshes before success', () async {
    final id = prepare();
    data.barrier = Completer();
    final work = cubit.confirmed(id, true);
    await cubit.confirmed(id, true);
    expect(data.writes, 1);
    expect(data.refreshes, 0);
    expect(cubit.state.busy, isTrue);
    data.barrier!.complete();
    await work;
    expect(data.refreshes, 1);
    expect(cubit.state.effect!.message, 'Backup ripristinato.');
  });
  test('write failure does not refresh', () async {
    data.failWrite = true;
    await cubit.confirmed(prepare(), true);
    expect(data.refreshes, 0);
    expect(cubit.state.effect!.message, contains('non sono stati modificati'));
  });
  test(
    'post-commit failure retries only refresh and blocks new operations',
    () async {
      data.failRefresh = true;
      await cubit.confirmed(prepare(), true);
      expect(cubit.state.refreshRequired, isTrue);
      expect(cubit.state.effect!.message, contains('Backup ripristinato'));
      cubit.restore();
      await cubit.export(csv: true);
      expect(data.exports, 0);
      data.failRefresh = false;
      await cubit.retryRefresh();
      expect(data.writes, 1);
      expect(data.refreshes, 2);
      expect(cubit.state.refreshRequired, isFalse);
    },
  );
  test('close during write still refreshes committed data', () async {
    final id = prepare();
    data.barrier = Completer();
    final work = cubit.confirmed(id, true);
    await cubit.close();
    data.barrier!.complete();
    await work;
    expect(data.refreshes, 1);
  });
  test(
    'refresh failure survives route close and retries without another write',
    () async {
      data.failRefresh = true;
      final id = prepare();
      data.barrier = Completer();
      final work = cubit.confirmed(id, true);
      await cubit.close();
      data.barrier!.complete();
      await work;
      final reopened = DataManagementCubit(data);
      expect(reopened.state.refreshRequired, isTrue);
      data.failRefresh = false;
      await reopened.retryRefresh();
      expect(data.writes, 1);
      expect(data.refreshes, 2);
      expect(reopened.state.refreshRequired, isFalse);
      await reopened.close();
    },
  );
  test('late picker result after close cannot restore', () async {
    cubit.restore();
    final id = cubit.state.effect!.id;
    await cubit.close();
    cubit.picked(id, '{}');
    expect(data.writes, 0);
  });
  test('export is single flight, share completion is consumed once', () async {
    data.barrier = Completer();
    final work = cubit.export(csv: false);
    await cubit.export(csv: true);
    expect(data.exports, 1);
    data.barrier!.complete();
    await work;
    final id = cubit.state.effect!.id;
    cubit.shareFinished(id, succeeded: true);
    expect(cubit.state.effect!.message, 'Pronto');
    cubit.shareFinished(id, succeeded: false);
    expect(cubit.state.effect!.message, 'Pronto');
  });
  test('export and sharing failures release busy for retry', () async {
    data.failExport = true;
    await cubit.export(csv: false);
    expect(cubit.state.busy, isFalse);
    data.failExport = false;
    await cubit.export(csv: false);
    cubit.shareFinished(cubit.state.effect!.id, succeeded: false);
    expect(cubit.state.effect!.message, contains('condividere'));
    expect(cubit.state.busy, isFalse);
  });
  test('closed export does not emit a share effect', () async {
    data.barrier = Completer();
    final work = cubit.export(csv: false);
    await cubit.close();
    data.barrier!.complete();
    await work;
    expect(cubit.state.effect, isNull);
  });
}
