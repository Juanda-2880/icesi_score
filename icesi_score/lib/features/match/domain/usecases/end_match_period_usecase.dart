import '../repository/match_repository.dart';

class EndMatchPeriodUseCase {
  final MatchRepository _repository;

  EndMatchPeriodUseCase(this._repository);

  Future<void> call(String periodId) => _repository.endMatchPeriod(periodId);
}
