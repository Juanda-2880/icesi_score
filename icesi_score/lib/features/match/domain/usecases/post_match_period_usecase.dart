import '../entities/match_period.dart';
import '../repository/match_repository.dart';

class PostMatchPeriodUseCase {
  final MatchRepository _repository;

  PostMatchPeriodUseCase(this._repository);

  Future<MatchPeriod> call({
    required String matchId,
    required String periodLabel,
  }) =>
      _repository.postMatchPeriod(matchId: matchId, periodLabel: periodLabel);
}
