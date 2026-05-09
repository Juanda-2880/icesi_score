class Match {
  final String id;
  final String sport;
  final String status;
  final String? matchDate;
  final String? matchTime;
  final String? venue;
  final int? homeScore;
  final int? awayScore;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamId;
  final String awayTeamName;
  final String leagueName;

  const Match({
    required this.id,
    required this.sport,
    required this.status,
    this.matchDate,
    this.matchTime,
    this.venue,
    this.homeScore,
    this.awayScore,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.leagueName,
  });
}
