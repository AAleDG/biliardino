import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

typedef DirectoryProvider = Future<Directory> Function();
typedef ShareLauncher = Future<ShareResult> Function(ShareParams params);

class CsvShareService {
  const CsvShareService({
    required this.temporaryDirectory,
    required this.shareLauncher,
  });

  factory CsvShareService.platform() {
    return CsvShareService(
      temporaryDirectory: getTemporaryDirectory,
      shareLauncher: SharePlus.instance.share,
    );
  }

  final DirectoryProvider temporaryDirectory;
  final ShareLauncher shareLauncher;

  Future<File> shareCsv({
    required String csv,
    required String fileName,
    required String subject,
    required String text,
    required Rect? sharePositionOrigin,
  }) async {
    if (csv.trim().isEmpty) {
      throw ArgumentError.value(csv, 'csv', 'CSV content cannot be empty.');
    }
    if (fileName.trim().isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'File name is required.');
    }

    final directory = await temporaryDirectory();
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(csv);
    await shareLauncher(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'text/csv',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        subject: subject,
        text: text,
        title: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return file;
  }
}
