import 'dart:convert';

import 'package:biliardino/models/game_match.dart';
import 'package:biliardino/models/player.dart';
import 'package:biliardino/services/data_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_database.dart';

void main() {
  final player1 = Player(
    id: 'p1',
    name: 'Alice, "Ace"',
    createdAt: DateTime.utc(2026),
    isPresent: true,
  );
  final player2 = Player(
    id: 'p2',
    name: 'Bob',
    createdAt: DateTime.utc(2026, 1, 2),
    isPresent: false,
  );
  final match = GameMatch(
    id: 'm1',
    playedAt: DateTime.utc(2026, 2, 3),
    mode: MatchMode.oneVsOne,
    t1p1: 'p1',
    t1p2: '',
    t2p1: 'p2',
    t2p2: '',
    t1Score: 2,
    t2Score: 1,
    winningTeam: 1,
    scorerIds: const ['p1', 'p2', 'p1'],
  );

  test('exports and parses the current version without losing data', () async {
    final database = FakeDatabaseHelper(
      players: [player1, player2],
      matches: [match],
    );
    final service = DataBackupService(database);

    final json = await service.createJson(DateTime.utc(2026, 8, 28));
    final data = service.parse(json);

    expect(jsonDecode(json)['version'], DataBackupService.currentVersion);
    expect(data.players.map((player) => player.id), ['p1', 'p2']);
    expect(data.matches.single.scorerIds, ['p1', 'p2', 'p1']);
    expect(service.summarize(data).matches, 1);
  });

  test('supports the older unversioned database-map format', () {
    final database = FakeDatabaseHelper();
    final service = DataBackupService(database);
    final legacy = jsonEncode({
      'players': [player1.toMap(), player2.toMap()],
      'matches': [match.toMap()],
    });

    final data = service.parse(legacy);

    expect(
      data.players.singleWhere((player) => player.id == 'p1').name,
      player1.name,
    );
    expect(data.matches.single.mode, MatchMode.oneVsOne);
  });

  test('rejects malformed, unsupported, and inconsistent backups', () {
    final service = DataBackupService(FakeDatabaseHelper());
    expect(() => service.parse('{oops'), throwsFormatException);
    expect(
      () => service.parse(
        jsonEncode({
          'version': 99,
          'players': <Object?>[],
          'matches': <Object?>[],
        }),
      ),
      throwsFormatException,
    );
    final invalidReference = jsonEncode({
      'version': 1,
      'players': [_currentPlayer(player1)],
      'matches': [_currentMatch(match)],
    });
    expect(() => service.parse(invalidReference), throwsFormatException);
  });

  test('restore replaces both collections only after validation', () async {
    final database = FakeDatabaseHelper(
      players: [player1],
      matches: const <GameMatch>[],
    );
    final service = DataBackupService(database);
    final data = BackupData(players: [player1, player2], matches: [match]);

    await service.restore(data);

    expect(database.players, hasLength(2));
    expect(database.matches.single.id, 'm1');
    await expectLater(
      service.restore(BackupData(players: [player1], matches: [match])),
      throwsFormatException,
    );
    expect(database.players, hasLength(2));
    expect(database.matches.single.id, 'm1');
  });

  test('CSV is readable and safely escapes names', () {
    final csv = MatchHistoryCsvService.build([player1, player2], [match]);

    expect(csv, contains('"Alice, ""Ace"""'));
    expect(csv, contains('"2-1"'));
    expect(csv, contains('"Alice, ""Ace"""'));
    expect(csv.endsWith('\r\n'), isTrue);
  });
}

Map<String, Object?> _currentPlayer(Player player) => {
  'id': player.id,
  'name': player.name,
  'createdAt': player.createdAt.toUtc().toIso8601String(),
  'isPresent': player.isPresent,
};

Map<String, Object?> _currentMatch(GameMatch match) => {
  'id': match.id,
  'playedAt': match.playedAt.toUtc().toIso8601String(),
  'mode': match.mode.dbValue,
  'team1': match.team1,
  'team2': match.team2,
  'score1': match.t1Score,
  'score2': match.t2Score,
  'winningTeam': match.winningTeam,
  'scorerIds': match.scorerIds,
  'isRivalry': match.isRivalry,
};
