import '../entities/match_period.dart';
import '../repository/match_repository.dart';

class GetMatchPeriodsUseCase {
  final MatchRepository _repository;

  GetMatchPeriodsUseCase(this._repository);

  Future<({MatchPeriod? activePeriod, List<String> closedPeriodLabels})> call(
          String matchId) =>
      _repository.getMatchPeriods(matchId);
}
