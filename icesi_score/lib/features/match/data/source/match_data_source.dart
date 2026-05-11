import '../../domain/entities/league.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/team.dart';

abstract class MatchDataSource {
  Future<List<Team>> getTeams(String idToken);
  Future<List<League>> getLeagues(String idToken);
  Future<List<Match>> getMatches(String idToken, String sport);
  Future<void> createMatch({
    required String idToken,
    required String sport,
    required String homeTeamId,
    required String awayTeamId,
    required String leagueId,
    required String matchDate,
    required String matchTime,
    required String venue,
    String? notes,
  });
  Future<void> updateMatch({
    required String idToken,
    required String id,
    required String sport,
    required String homeTeamId,
    required String awayTeamId,
    required String leagueId,
    required String matchDate,
    required String matchTime,
    required String venue,
    String? notes,
  });
  Future<void> deleteMatch({required String idToken, required String id});
}
