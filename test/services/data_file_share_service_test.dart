import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:biliardino/services/data_file_share_service.dart';

void main() {
  test(
    'writes exact payload and passes metadata and origin to native share',
    () async {
      final dir = await Directory.systemTemp.createTemp('pass-share-');
      addTearDown(() => dir.delete(recursive: true));
      ShareParams? sent;
      final service = DataFileShareService(
        temporaryDirectory: () async => dir,
        shareLauncher: (params) async {
          sent = params;
          return const ShareResult('', ShareResultStatus.dismissed);
        },
      );
      final file = await service.share(
        content: 'a,b\n1,2',
        fileName: 'history.csv',
        mimeType: 'text/csv',
        subject: 'Storico',
        sharePositionOrigin: const Rect.fromLTWH(10, 20, 40, 50),
      );
      expect(await file.readAsString(), 'a,b\n1,2');
      expect(sent!.fileNameOverrides, ['history.csv']);
      expect(sent!.files!.single.mimeType, 'text/csv');
      expect(sent!.subject, 'Storico');
      expect(sent!.sharePositionOrigin, const Rect.fromLTWH(10, 20, 40, 50));
    },
  );
  test('native failure propagates and empty content never launches', () async {
    final dir = await Directory.systemTemp.createTemp('pass-share-');
    addTearDown(() => dir.delete(recursive: true));
    var launches = 0;
    final service = DataFileShareService(
      temporaryDirectory: () async => dir,
      shareLauncher: (_) async {
        launches++;
        throw StateError('native');
      },
    );
    Future<void> share(String value) async => service.share(
      content: value,
      fileName: 'x.json',
      mimeType: 'application/json',
      subject: 'Backup',
      sharePositionOrigin: null,
    );
    await expectLater(share(''), throwsArgumentError);
    expect(launches, 0);
    await expectLater(share('{}'), throwsStateError);
    expect(launches, 1);
  });
}
