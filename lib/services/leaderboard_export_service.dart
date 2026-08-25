import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/player_stats.dart';
import 'leaderboard_csv_service.dart';

class LeaderboardExportResult {
  const LeaderboardExportResult({
    required this.path,
    required this.desktopPath,
    required this.fileName,
    required this.csv,
  });

  final String path;
  final String? desktopPath;
  final String fileName;
  final String csv;
}

class LeaderboardExportService {
  const LeaderboardExportService._();

  static Future<LeaderboardExportResult> exportCsv(
    List<PlayerStats> stats,
    DateTime exportedAt,
  ) async {
    if (stats.isEmpty) {
      throw ArgumentError.value(stats, 'stats', 'Leaderboard cannot be empty.');
    }
    final directory = await _exportDirectory();
    final csv = LeaderboardCsvService.build(stats);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(exportedAt);
    final fileName = 'classifica_$timestamp.csv';
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(csv);
    final desktopPath = await _copyToHostDesktop(
      sourceFile: file,
      fileName: fileName,
    );
    return LeaderboardExportResult(
      path: file.path,
      desktopPath: desktopPath,
      fileName: fileName,
      csv: csv,
    );
  }

  static Future<Directory> _exportDirectory() async {
    try {
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory != null) {
        return downloadsDirectory;
      }
    } on Object {
      // Some platforms expose no downloads directory through path_provider.
    }
    return getApplicationDocumentsDirectory();
  }

  static Future<String?> _copyToHostDesktop({
    required File sourceFile,
    required String fileName,
  }) async {
    if (!Platform.isIOS) {
      return null;
    }
    final userHome = _hostUserHome(sourceFile.path);
    if (userHome == null) {
      return null;
    }
    final desktop = Directory(p.join(userHome, 'Desktop'));
    if (!await desktop.exists()) {
      return null;
    }
    final destination = File(p.join(desktop.path, fileName));
    await sourceFile.copy(destination.path);
    return destination.path;
  }

  static String? _hostUserHome(String path) {
    final parts = p.split(path);
    if (parts.length < 3 || parts[0] != '/' || parts[1] != 'Users') {
      return null;
    }
    return p.join(parts[0], parts[1], parts[2]);
  }
}
