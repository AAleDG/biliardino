import '../data/database_helper.dart';
import '../models/match_rules.dart';

class MatchRulesRepository {
  MatchRulesRepository(this._db);

  static const _modeKey = 'match_rules.mode';
  static const _targetScoreKey = 'match_rules.target_score';
  static const _winByTwoKey = 'match_rules.win_by_two';

  final DatabaseHelper _db;
  MatchRules _rules = MatchRules.defaultRules;

  MatchRules get rules => _rules;

  Future<void> load() async {
    final values = await _db.getSettings([
      _modeKey,
      _targetScoreKey,
      _winByTwoKey,
    ]);
    final targetScore =
        int.tryParse(values[_targetScoreKey] ?? '') ??
        MatchRules.defaultRules.targetScore;
    _rules = MatchRules(
      mode: MatchRuleMode.fromDbValue(values[_modeKey]),
      targetScore: targetScore,
      winByTwo: values[_winByTwoKey] == '1',
    );
  }

  Future<void> save(MatchRules rules) async {
    final normalized = rules.copyWith();
    await _db.setSettings({
      _modeKey: normalized.mode.dbValue,
      _targetScoreKey: '${normalized.targetScore}',
      _winByTwoKey: normalized.winByTwo ? '1' : '0',
    });
    _rules = normalized;
  }
}
