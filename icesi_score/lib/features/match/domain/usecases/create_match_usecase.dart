import '../repository/match_repository.dart';

class CreateMatchUseCase {
  final MatchRepository _repository;
  const CreateMatchUseCase(this._repository);

  Future<void> call({
    required String sport,
    required String homeTeamId,
    required String awayTeamId,
    required String leagueId,
    required String matchDate,
    required String matchTime,
    required String venue,
    String? notes,
  }) =>
      _repository.createMatch(
        sport: sport,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        leagueId: leagueId,
        matchDate: matchDate,
        matchTime: matchTime,
        venue: venue,
        notes: notes,
      );
}
