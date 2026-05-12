class SoccerEvent {
  final String id;
  final String matchId;
  final String eventType;
  final int minute;
  final String? playerName;
  final String? teamId;
  final String? teamName;
  final String? scoreAtMoment;
  final String? parentEventId;
  final String? secondaryPlayerName;

  const SoccerEvent({
    required this.id,
    required this.matchId,
    required this.eventType,
    required this.minute,
    this.playerName,
    this.teamId,
    this.teamName,
    this.scoreAtMoment,
    this.parentEventId,
    this.secondaryPlayerName,
  });
}
