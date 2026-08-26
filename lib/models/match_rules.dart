import 'package:equatable/equatable.dart';

enum MatchRuleMode {
  free('free'),
  firstTo('firstTo');

  const MatchRuleMode(this.dbValue);

  final String dbValue;

  static MatchRuleMode fromDbValue(String? value) {
    for (final mode in MatchRuleMode.values) {
      if (mode.dbValue == value) {
        return mode;
      }
    }
    return MatchRuleMode.free;
  }
}

class MatchRules extends Equatable {
  const MatchRules({
    required this.mode,
    required this.targetScore,
    required this.winByTwo,
  });

  static const minTargetScore = 1;
  static const maxTargetScore = 99;
  static const defaultRules = MatchRules(
    mode: MatchRuleMode.free,
    targetScore: 10,
    winByTwo: false,
  );

  final MatchRuleMode mode;
  final int targetScore;
  final bool winByTwo;

  bool get isFree => mode == MatchRuleMode.free;

  int? winningTeam({required int score1, required int score2}) {
    if (isFree) {
      return null;
    }
    if (score1 < targetScore && score2 < targetScore) {
      return null;
    }
    final margin = (score1 - score2).abs();
    if (winByTwo && margin < 2) {
      return null;
    }
    if (score1 == score2) {
      return null;
    }
    return score1 > score2 ? 1 : 2;
  }

  MatchRules copyWith({MatchRuleMode? mode, int? targetScore, bool? winByTwo}) {
    return MatchRules(
      mode: mode ?? this.mode,
      targetScore: _normalizeTargetScore(targetScore ?? this.targetScore),
      winByTwo: winByTwo ?? this.winByTwo,
    );
  }

  static int _normalizeTargetScore(int value) {
    return value.clamp(minTargetScore, maxTargetScore).toInt();
  }

  @override
  List<Object?> get props => [mode, targetScore, winByTwo];
}
