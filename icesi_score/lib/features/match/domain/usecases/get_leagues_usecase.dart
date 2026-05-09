import '../entities/league.dart';
import '../repository/match_repository.dart';

class GetLeaguesUseCase {
  final MatchRepository _repository;
  const GetLeaguesUseCase(this._repository);

  Future<List<League>> call() => _repository.getLeagues();
}
