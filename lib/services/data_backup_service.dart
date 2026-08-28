import 'dart:convert';

import '../data/database_helper.dart';
import '../models/game_match.dart';
import '../models/player.dart';

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

class DataBackupService {
  const DataBackupService(this._database);

  static const currentVersion = 1;
  final DatabaseHelper _database;

  Future<String> createJson(DateTime exportedAt) async {
    final players = await _database.getPlayers();
    final matches = await _database.getMatches();
    return const JsonEncoder.withIndent('  ').convert({
      'version': currentVersion,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'players': players.map(_playerToJson).toList(),
      'matches': matches.map(_matchToJson).toList(),
    });
  }

  BackupData parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Invalid backup JSON: ${error.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be an object.');
    }
    final version = decoded['version'] ?? 0;
    if (version is! int || version < 0 || version > currentVersion) {
      throw FormatException('Unsupported backup version: $version.');
    }
    final playersJson = _list(decoded, 'players');
    final matchesJson = _list(decoded, 'matches');
    final players = playersJson
        .map((item) => version == 0 ? _legacyPlayer(item) : _player(item))
        .toList(growable: false);
    final matches = matchesJson
        .map((item) => version == 0 ? _legacyMatch(item) : _match(item))
        .toList(growable: false);
    _validate(players, matches);
    return BackupData(players: players, matches: matches);
  }

  ImportSummary summarize(BackupData data) =>
      ImportSummary(players: data.players.length, matches: data.matches.length);

  Future<void> restore(BackupData data) async {
    _validate(data.players, data.matches);
    await _database.replacePlayersAndMatches(
      players: data.players,
      matches: data.matches,
    );
  }

  static Map<String, Object?> _playerToJson(Player player) => {
    'id': player.id,
    'name': player.name,
    'createdAt': player.createdAt.toUtc().toIso8601String(),
    'isPresent': player.isPresent,
  };

  static Map<String, Object?> _matchToJson(GameMatch match) => {
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

  static Player _player(Object? value) {
    final map = _object(value, 'player');
    return Player(
      id: _string(map, 'id'),
      name: _string(map, 'name'),
      createdAt: _date(map, 'createdAt'),
      isPresent: _bool(map, 'isPresent'),
    );
  }

  static GameMatch _match(Object? value) {
    final map = _object(value, 'match');
    final team1 = _strings(map, 'team1');
    final team2 = _strings(map, 'team2');
    return GameMatch(
      id: _string(map, 'id'),
      playedAt: _date(map, 'playedAt'),
      mode: MatchMode.fromDbValue(_string(map, 'mode')),
      t1p1: team1.isNotEmpty ? team1[0] : '',
      t1p2: team1.length > 1 ? team1[1] : '',
      t2p1: team2.isNotEmpty ? team2[0] : '',
      t2p2: team2.length > 1 ? team2[1] : '',
      t1Score: _int(map, 'score1'),
      t2Score: _int(map, 'score2'),
      winningTeam: _int(map, 'winningTeam'),
      scorerIds: _strings(map, 'scorerIds'),
      isRivalry: _bool(map, 'isRivalry'),
    );
  }

  static Player _legacyPlayer(Object? value) {
    final map = _object(value, 'player');
    return Player.fromMap(map);
  }

  static GameMatch _legacyMatch(Object? value) {
    final map = _object(value, 'match');
    return GameMatch.fromMap(map);
  }

  static void _validate(List<Player> players, List<GameMatch> matches) {
    final ids = <String>{};
    final names = <String>{};
    for (final player in players) {
      if (player.id.trim().isEmpty || !ids.add(player.id)) {
        throw const FormatException('Player IDs must be non-empty and unique.');
      }
      final nameKey = Player.normalizedNameKey(player.name);
      if (nameKey.isEmpty || !names.add(nameKey)) {
        throw const FormatException(
          'Player names must be non-empty and unique.',
        );
      }
    }
    final matchIds = <String>{};
    for (final match in matches) {
      if (match.id.trim().isEmpty || !matchIds.add(match.id)) {
        throw const FormatException('Match IDs must be non-empty and unique.');
      }
      final participants = match.allPlayers;
      if (participants.length != match.mode.teamSize * 2 ||
          participants.toSet().length != participants.length ||
          participants.any((id) => !ids.contains(id))) {
        throw FormatException(
          'Match ${match.id} has invalid player references.',
        );
      }
      if (match.t1Score < 0 ||
          match.t2Score < 0 ||
          match.t1Score == match.t2Score ||
          match.winningTeam != (match.t1Score > match.t2Score ? 1 : 2)) {
        throw FormatException('Match ${match.id} has an invalid result.');
      }
      if (match.scorerIds.any((id) => !participants.contains(id))) {
        throw FormatException('Match ${match.id} has an invalid scorer.');
      }
      final team1Goals = match.scorerIds.where(match.team1.contains).length;
      final team2Goals = match.scorerIds.where(match.team2.contains).length;
      if (team1Goals != match.t1Score || team2Goals != match.t2Score) {
        throw FormatException(
          'Match ${match.id} scorer history does not match its score.',
        );
      }
    }
  }

  static List<Object?> _list(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! List<Object?>) {
      throw FormatException('$key must be a list.');
    }
    return value;
  }

  static Map<String, dynamic> _object(Object? value, String label) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('$label must be an object.');
    }
    return value;
  }

  static String _string(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String) throw FormatException('$key must be a string.');
    return value;
  }

  static int _int(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! int) throw FormatException('$key must be an integer.');
    return value;
  }

  static bool _bool(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! bool) throw FormatException('$key must be a boolean.');
    return value;
  }

  static DateTime _date(Map<String, dynamic> map, String key) {
    final value = _string(map, key);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw FormatException('$key must be an ISO-8601 date.');
    return parsed;
  }

  static List<String> _strings(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('$key must be a string list.');
    }
    return List<String>.from(value);
  }
}

class MatchHistoryCsvService {
  const MatchHistoryCsvService._();

  static String build(List<Player> players, List<GameMatch> matches) {
    final names = {for (final player in players) player.id: player.name};
    final rows = <List<String>>[
      const [
        'played_at',
        'mode',
        'team_1',
        'team_2',
        'score',
        'winner',
        'rivalry',
      ],
      for (final match in matches)
        [
          match.playedAt.toUtc().toIso8601String(),
          match.mode.dbValue,
          match.team1.map((id) => names[id] ?? id).join(' + '),
          match.team2.map((id) => names[id] ?? id).join(' + '),
          '${match.t1Score}-${match.t2Score}',
          (match.winningTeam == 1 ? match.team1 : match.team2)
              .map((id) => names[id] ?? id)
              .join(' + '),
          match.isRivalry ? 'yes' : 'no',
        ],
    ];
    return '${rows.map((row) => row.map(_escape).join(',')).join('\r\n')}\r\n';
  }

  static String _escape(String value) => '"${value.replaceAll('"', '""')}"';
}
