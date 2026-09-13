import 'game_match.dart';
import 'player.dart';

class BackupData {
  const BackupData({required this.players, required this.matches});
  final List<Player> players;
  final List<GameMatch> matches;
}

class ImportSummary {
  const ImportSummary({required this.players, required this.matches});
  final int players;
  final int matches;
}

class DataExport {
  const DataExport({
    required this.content,
    required this.fileName,
    required this.mimeType,
    required this.subject,
    required this.message,
  });
  final String content, fileName, mimeType, subject, message;
}
