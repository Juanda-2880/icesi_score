import '../entities/soccer_event.dart';
import '../repository/match_repository.dart';

class GetSoccerEventsUseCase {
  final MatchRepository _repository;

  GetSoccerEventsUseCase(this._repository);

  Future<List<SoccerEvent>> call(String matchId) =>
      _repository.getSoccerEvents(matchId);
}
