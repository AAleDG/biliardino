import 'package:equatable/equatable.dart';

class RivalryOverview extends Equatable {
  const RivalryOverview({
    required this.team1Ids,
    required this.team2Ids,
    required this.totalMatches,
    required this.team1Wins,
    required this.team2Wins,
    required this.team1Goals,
    required this.team2Goals,
  });

  final List<String> team1Ids;
  final List<String> team2Ids;
  final int totalMatches;
  final int team1Wins;
  final int team2Wins;
  final int team1Goals;
  final int team2Goals;

  bool get hasMatches => totalMatches > 0;
  bool get isTied => team1Wins == team2Wins;

  @override
  List<Object?> get props => [
        team1Ids,
        team2Ids,
        totalMatches,
        team1Wins,
        team2Wins,
        team1Goals,
        team2Goals,
      ];
}
