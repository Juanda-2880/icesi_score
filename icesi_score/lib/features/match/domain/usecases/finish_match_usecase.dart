import '../repository/match_repository.dart';

class FinishMatchUseCase {
  final MatchRepository _repository;

  FinishMatchUseCase(this._repository);

  Future<void> call(String matchId) => _repository.finishMatch(matchId);
}
