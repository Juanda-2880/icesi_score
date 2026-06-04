import '../repository/match_repository.dart';
import '../entities/volleyball_set.dart';

class PostVolleyballSetUseCase {
  final MatchRepository _repository;
  PostVolleyballSetUseCase(this._repository);

  Future<VolleyballSet> call({required String matchId}) {
    return _repository.postVolleyballSet(matchId: matchId);
  }
}
