import '../repository/match_repository.dart';

class DeleteMatchUseCase {
  final MatchRepository _repository;

  DeleteMatchUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteMatch(id);
}
