import 'package:biliardino/models/match_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatchRules', () {
    test('free scoring never completes automatically', () {
      const rules = MatchRules.defaultRules;

      expect(rules.winningTeam(score1: 99, score2: 0), isNull);
      expect(rules.winningTeam(score1: 10, score2: 9), isNull);
    });

    test('first-to-N completes when a team reaches the target', () {
      const rules = MatchRules(
        mode: MatchRuleMode.firstTo,
        targetScore: 10,
        winByTwo: false,
      );

      expect(rules.winningTeam(score1: 9, score2: 0), isNull);
      expect(rules.winningTeam(score1: 10, score2: 9), 1);
      expect(rules.winningTeam(score1: 4, score2: 10), 2);
    });

    test('win-by-two requires the target and two goals of margin', () {
      const rules = MatchRules(
        mode: MatchRuleMode.firstTo,
        targetScore: 10,
        winByTwo: true,
      );

      expect(rules.winningTeam(score1: 10, score2: 9), isNull);
      expect(rules.winningTeam(score1: 11, score2: 10), isNull);
      expect(rules.winningTeam(score1: 11, score2: 9), 1);
      expect(rules.winningTeam(score1: 10, score2: 12), 2);
    });

    test('target score is clamped to the supported range', () {
      expect(MatchRules.defaultRules.copyWith(targetScore: 0).targetScore, 1);
      expect(
        MatchRules.defaultRules.copyWith(targetScore: 120).targetScore,
        99,
      );
    });
  });
}
