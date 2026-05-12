import '../entities/match_period.dart';
import '../repository/match_repository.dart';

class GetMatchPeriodUseCase {
  final MatchRepository _repository;

  GetMatchPeriodUseCase(this._repository);

  Future<MatchPeriod?> call(String matchId) =>
      _repository.getActivePeriod(matchId);
}
