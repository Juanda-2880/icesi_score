import '../entities/soccer_event.dart';
import '../repository/match_repository.dart';

class PostSoccerEventUseCase {
  final MatchRepository _repository;
  PostSoccerEventUseCase(this._repository);

  Future<({SoccerEvent event, int homeScore, int awayScore})> call({
    required String matchId,
    required String eventType,
    required String mainPlayerId,
    required int eventMinute,
    String? secondaryPlayerId,
    String? parentEventId,
    String? assistPlayerId,
    String? note,
  }) =>
      _repository.postSoccerEvent(
        matchId: matchId,
        eventType: eventType,
        mainPlayerId: mainPlayerId,
        eventMinute: eventMinute,
        secondaryPlayerId: secondaryPlayerId,
        parentEventId: parentEventId,
        assistPlayerId: assistPlayerId,
        note: note,
      );
}
