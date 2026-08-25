import 'dart:io';

import 'package:biliardino/services/csv_share_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('CsvShareService', () {
    test('writes the CSV file and opens the share sheet with that file',
        () async {
      final directory = await Directory.systemTemp.createTemp('csv-share-test');
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      ShareParams? capturedParams;
      final service = CsvShareService(
        temporaryDirectory: () async => directory,
        shareLauncher: (params) async {
          capturedParams = params;
          return const ShareResult(
            'ok',
            ShareResultStatus.success,
          );
        },
      );

      final file = await service.shareCsv(
        csv: 'a,b',
        fileName: 'classifica.csv',
        subject: 'Classifica',
        text: 'CSV classifica',
        sharePositionOrigin: null,
      );

      expect(await file.readAsString(), 'a,b');
      expect(file.path, endsWith('classifica.csv'));
      expect(capturedParams?.files, hasLength(1));
      expect(capturedParams?.fileNameOverrides, ['classifica.csv']);
      expect(capturedParams?.subject, 'Classifica');
    });
  });
}
