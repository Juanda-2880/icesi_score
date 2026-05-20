import '../../domain/entities/league.dart';
import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/entities/soccer_event.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/volleyball_event.dart';
import '../../domain/entities/volleyball_set.dart';

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
  Future<List<SoccerEvent>> getSoccerEvents(String idToken, String matchId);
  Future<MatchPeriod?> getActivePeriod(String idToken, String matchId);
  Future<({MatchPeriod? activePeriod, List<String> closedPeriodLabels})> getMatchPeriods(String idToken, String matchId);
  Future<MatchPeriod> postMatchPeriod({required String idToken, required String matchId, required String periodLabel});
  Future<void> endMatchPeriod({required String idToken, required String periodId});
  Future<void> finishMatch({required String idToken, required String matchId});
  Future<({List<VolleyballSet> sets, List<VolleyballEvent> events})> getVolleyballData(String idToken, String matchId);
  Future<List<LineupPlayer>> getMatchLineup(String idToken, String matchId);
  Future<({SoccerEvent event, int homeScore, int awayScore})> postSoccerEvent({
    required String idToken,
    required String matchId,
    required String eventType,
    required String mainPlayerId,
    required int eventMinute,
    String? secondaryPlayerId,
    String? parentEventId,
    String? assistPlayerId,
    String? note,
  });
}
