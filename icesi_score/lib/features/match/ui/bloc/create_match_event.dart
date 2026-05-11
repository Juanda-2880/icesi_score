import '../../domain/entities/match.dart';

abstract class CreateMatchEvent {
  const CreateMatchEvent();
}

class CreateMatchStartedEvent extends CreateMatchEvent {
  const CreateMatchStartedEvent();
}

class CreateMatchEditStartedEvent extends CreateMatchEvent {
  final Match existingMatch;
  const CreateMatchEditStartedEvent(this.existingMatch);
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

class EditMatchSubmittedEvent extends CreateMatchEvent {
  final String homeTeamId;
  final String awayTeamId;
  final String leagueId;
  final String matchDate;
  final String matchTime;
  final String venue;
  final String? notes;

  const EditMatchSubmittedEvent({
    required this.homeTeamId,
    required this.awayTeamId,
    required this.leagueId,
    required this.matchDate,
    required this.matchTime,
    required this.venue,
    this.notes,
  });
}

class DeleteMatchRequestedEvent extends CreateMatchEvent {
  final String matchId;
  const DeleteMatchRequestedEvent(this.matchId);
}
