import '../entities/lineup_player.dart';
import '../repository/match_repository.dart';

class GetMatchLineupUseCase {
  final MatchRepository _repository;
  GetMatchLineupUseCase(this._repository);

  Future<List<LineupPlayer>> call(String matchId) =>
      _repository.getMatchLineup(matchId);
}
