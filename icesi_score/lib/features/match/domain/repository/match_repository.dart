import '../entities/league.dart';
import '../entities/match.dart';
import '../entities/team.dart';

abstract class MatchRepository {
  Future<List<Team>> getTeams();
  Future<List<League>> getLeagues();
  Future<List<Match>> getMatches(String sport);
  Future<void> createMatch({
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
  Future<void> deleteMatch(String id);
}
