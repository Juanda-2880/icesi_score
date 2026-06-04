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
  final String leagueId;
  final String leagueName;
  final String? notes;

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
    required this.leagueId,
    required this.leagueName,
    this.notes,
  });

  Match copyWith({int? homeScore, int? awayScore, String? status}) => Match(
        id: id,
        sport: sport,
        status: status ?? this.status,
        matchDate: matchDate,
        matchTime: matchTime,
        venue: venue,
        homeScore: homeScore ?? this.homeScore,
        awayScore: awayScore ?? this.awayScore,
        homeTeamId: homeTeamId,
        homeTeamName: homeTeamName,
        awayTeamId: awayTeamId,
        awayTeamName: awayTeamName,
        leagueId: leagueId,
        leagueName: leagueName,
        notes: notes,
      );
}
