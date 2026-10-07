import 'player_badge.dart';

/// Displayable ranking data for an individual or a recurring pair.
abstract interface class RankingStats {
  String get id;
  String get name;
  List<String> get memberNames;
  int get points;
  int get games;
  int get wins;
  int get losses;
  int get goalsScored;
  double get winRate;
  int get currentWinStreak;
  List<PlayerBadge> get badges;
}
