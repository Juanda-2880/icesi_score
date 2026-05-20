import '../../domain/entities/match.dart';

abstract class VolleyballLiveModeEvent {
  const VolleyballLiveModeEvent();
}

class VolleyballLiveModeStartedEvent extends VolleyballLiveModeEvent {
  final Match match;
  const VolleyballLiveModeStartedEvent(this.match);
}

class StartSetEvent extends VolleyballLiveModeEvent {
  const StartSetEvent();
}

class VolleyballEventSubmittedEvent extends VolleyballLiveModeEvent {
  final String eventType;
  final String teamId;
  final String? mainPlayerId;
  final String? secondaryPlayerId;
  final String? note;

  const VolleyballEventSubmittedEvent({
    required this.eventType,
    required this.teamId,
    this.mainPlayerId,
    this.secondaryPlayerId,
    this.note,
  });
}

class RotateTeamEvent extends VolleyballLiveModeEvent {
  final String teamId;
  const RotateTeamEvent(this.teamId);
}
