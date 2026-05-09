abstract class CreateMatchEvent {
  const CreateMatchEvent();
}

class CreateMatchStartedEvent extends CreateMatchEvent {
  const CreateMatchStartedEvent();
}

class CreateMatchSportSelectedEvent extends CreateMatchEvent {
  final String sport; // 'FOOTBALL' | 'VOLLEYBALL'
  const CreateMatchSportSelectedEvent(this.sport);
}

class CreateMatchSubmittedEvent extends CreateMatchEvent {
  final String homeTeamId;
  final String awayTeamId;
  final String leagueId;
  final String matchDate;
  final String matchTime;
  final String venue;
  final String? notes;

  const CreateMatchSubmittedEvent({
    required this.homeTeamId,
    required this.awayTeamId,
    required this.leagueId,
    required this.matchDate,
    required this.matchTime,
    required this.venue,
    this.notes,
  });
}
