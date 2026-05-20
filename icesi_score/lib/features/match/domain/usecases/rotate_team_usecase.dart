import '../repository/match_repository.dart';
import '../entities/lineup_player.dart';

class RotateTeamUseCase {
  final MatchRepository _repository;
  RotateTeamUseCase(this._repository);

  Future<List<LineupPlayer>> call({
    required String matchId,
    required String teamId,
  }) {
    return _repository.rotateTeam(matchId: matchId, teamId: teamId);
  }
}
