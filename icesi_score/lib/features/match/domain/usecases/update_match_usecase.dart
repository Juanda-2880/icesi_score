import '../repository/match_repository.dart';

class UpdateMatchUseCase {
  final MatchRepository _repository;

  UpdateMatchUseCase(this._repository);

  Future<void> call({
    required String id,
    required String sport,
    required String homeTeamId,
    required String awayTeamId,
    required String leagueId,
    required String matchDate,
    required String matchTime,
    required String venue,
    String? notes,
  }) =>
      _repository.updateMatch(
        id: id,
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
