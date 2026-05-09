import '../entities/match.dart';
import '../repository/match_repository.dart';

class GetMatchesUseCase {
  final MatchRepository _repository;

  GetMatchesUseCase(this._repository);

  Future<List<Match>> call(String sport) => _repository.getMatches(sport);
}
