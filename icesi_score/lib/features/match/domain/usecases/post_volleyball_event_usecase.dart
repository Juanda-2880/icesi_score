import '../repository/match_repository.dart';
import '../entities/volleyball_event.dart';

class PostVolleyballEventUseCase {
  final MatchRepository _repository;
  PostVolleyballEventUseCase(this._repository);

  Future<({
    VolleyballEvent event,
    int homeSetScore,
    int awaySetScore,
    int homeSets,
    int awaySets,
    bool setComplete,
    bool matchFinished,
  })> call({
    required String setId,
    required String eventType,
    required String teamId,
    String? mainPlayerId,
    String? secondaryPlayerId,
    String? note,
  }) {
    return _repository.postVolleyballEvent(
      setId: setId,
      eventType: eventType,
      teamId: teamId,
      mainPlayerId: mainPlayerId,
      secondaryPlayerId: secondaryPlayerId,
      note: note,
    );
  }
}
