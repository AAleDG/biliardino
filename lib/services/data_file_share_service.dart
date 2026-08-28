import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataFileShareService {
  const DataFileShareService({
    required this.temporaryDirectory,
    required this.shareLauncher,
  });

  factory DataFileShareService.platform() => DataFileShareService(
    temporaryDirectory: getTemporaryDirectory,
    shareLauncher: SharePlus.instance.share,
  );

  final Future<Directory> Function() temporaryDirectory;
  final Future<ShareResult> Function(ShareParams params) shareLauncher;

  Future<File> share({
    required String content,
    required String fileName,
    required String mimeType,
    required String subject,
    required Rect? sharePositionOrigin,
  }) async {
    if (content.isEmpty) throw ArgumentError('Export content cannot be empty.');
    final directory = await temporaryDirectory();
    final file = File(path.join(directory.path, fileName));
    await file.writeAsString(content, flush: true);
    await shareLauncher(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType, name: fileName)],
        fileNameOverrides: [fileName],
        subject: subject,
        title: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return file;
  }
}
