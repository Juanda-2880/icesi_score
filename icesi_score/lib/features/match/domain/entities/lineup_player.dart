class LineupPlayer {
  final String id;
  final String playerId;
  final String playerName;
  final int jerseyNumber;
  final String teamId;
  final String teamName;
  final String status; // STARTER | ON_FIELD | ON_BENCH | EXPELLED
  final String? positionCoordinate; // '1'-'6' for volleyball

  const LineupPlayer({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.jerseyNumber,
    required this.teamId,
    required this.teamName,
    required this.status,
    this.positionCoordinate,
  });

  LineupPlayer copyWith({String? status, String? positionCoordinate}) => LineupPlayer(
        id: id,
        playerId: playerId,
        playerName: playerName,
        jerseyNumber: jerseyNumber,
        teamId: teamId,
        teamName: teamName,
        status: status ?? this.status,
        positionCoordinate: positionCoordinate ?? this.positionCoordinate,
      );
}
