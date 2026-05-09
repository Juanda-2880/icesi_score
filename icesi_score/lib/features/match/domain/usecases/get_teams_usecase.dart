import '../entities/team.dart';
import '../repository/match_repository.dart';

class GetTeamsUseCase {
  final MatchRepository _repository;
  const GetTeamsUseCase(this._repository);

  Future<List<Team>> call() => _repository.getTeams();
}
