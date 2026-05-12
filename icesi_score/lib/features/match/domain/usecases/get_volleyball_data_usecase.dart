import '../entities/volleyball_event.dart';
import '../entities/volleyball_set.dart';
import '../repository/match_repository.dart';

class GetVolleyballDataUseCase {
  final MatchRepository _repository;
  GetVolleyballDataUseCase(this._repository);

  Future<({List<VolleyballSet> sets, List<VolleyballEvent> events})> call(String matchId) {
    return _repository.getVolleyballData(matchId);
  }
}
