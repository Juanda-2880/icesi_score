class VolleyballEvent {
  final String id;
  final String setId;
  final int setNumber;
  final String eventType;
  final String? playerName;
  final String? teamId;
  final String? teamName;
  final String? scoreMoment;

  const VolleyballEvent({
    required this.id,
    required this.setId,
    required this.setNumber,
    required this.eventType,
    this.playerName,
    this.teamId,
    this.teamName,
    this.scoreMoment,
  });
}
