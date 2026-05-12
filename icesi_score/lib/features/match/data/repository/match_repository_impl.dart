import '../../../auth/data/source/remote_auth_data_source.dart';
import '../../domain/entities/league.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/entities/soccer_event.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/volleyball_event.dart';
import '../../domain/entities/volleyball_set.dart';
import '../../domain/exceptions/match_exception.dart';
import '../../domain/repository/match_repository.dart';
import '../source/match_api_data_source.dart';
import '../source/match_data_source.dart';

class MatchRepositoryImpl implements MatchRepository {
  final RemoteAuthDataSource _cognito;
  final MatchDataSource _matchApi;

  MatchRepositoryImpl(
    RemoteAuthDataSource cognito, [
    MatchDataSource? matchApi,
  ])  : _cognito = cognito,
        _matchApi = matchApi ?? MatchApiDataSource();

  @override
  Future<List<Team>> getTeams() async {
    try {
      final idToken = await _cognito.getIdToken();
      return _matchApi.getTeams(idToken);
    } on MatchException {
      rethrow;
    } on Exception {
      throw const MatchException('Error al obtener equipos. Intenta de nuevo.');
    }
  }

  @override
  Future<List<League>> getLeagues() async {
    try {
      final idToken = await _cognito.getIdToken();
      return _matchApi.getLeagues(idToken);
    } on MatchException {
      rethrow;
    } on Exception {
      throw const MatchException('Error al obtener ligas. Intenta de nuevo.');
    }
  }

  @override
  Future<List<Match>> getMatches(String sport) async {
    try {
      final idToken = await _cognito.getIdToken();
      return _matchApi.getMatches(idToken, sport);
    } on MatchException {
      rethrow;
    } on Exception {
      throw const MatchException('Error al obtener partidos. Intenta de nuevo.');
    }
  }

  @override
  Future<void> createMatch({
    required String sport,
    required String homeTeamId,
    required String awayTeamId,
    required String leagueId,
    required String matchDate,
    required String matchTime,
    required String venue,
    String? notes,
  }) async {
    try {
      final idToken = await _cognito.getIdToken();
      await _matchApi.createMatch(
        idToken: idToken,
        sport: sport,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        leagueId: leagueId,
        matchDate: matchDate,
        matchTime: matchTime,
        venue: venue,
        notes: notes,
      );
    } on MatchException {
      rethrow;
    } on Exception {
      throw const MatchException('Error al crear el partido. Intenta de nuevo.');
    }
  }

  @override
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
  }) async {
    try {
      final idToken = await _cognito.getIdToken();
      await _matchApi.updateMatch(
        idToken: idToken,
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
    } on MatchException {
      rethrow;
    } on Exception {
      throw const MatchException('Error al editar el partido. Intenta de nuevo.');
    }
  }

  @override
  Future<void> deleteMatch(String id) async {
    try {
      final idToken = await _cognito.getIdToken();
      await _matchApi.deleteMatch(idToken: idToken, id: id);
    } on MatchException {
      rethrow;
    } on Exception {
      throw const MatchException('Error al eliminar el partido. Intenta de nuevo.');
    }
  }

  @override
  Future<List<SoccerEvent>> getSoccerEvents(String matchId) async {
    try {
      final idToken = await _cognito.getIdToken();
      return _matchApi.getSoccerEvents(idToken, matchId);
    } on MatchException {
      rethrow;
    } on Exception {
      throw const MatchException('Error al obtener eventos. Intenta de nuevo.');
    }
  }

  @override
  Future<MatchPeriod?> getActivePeriod(String matchId) async {
    try {
      final idToken = await _cognito.getIdToken();
      return _matchApi.getActivePeriod(idToken, matchId);
    } on MatchException {
      rethrow;
    } on Exception {
      throw const MatchException('Error al obtener período. Intenta de nuevo.');
    }
  }

  @override
  Future<({List<VolleyballSet> sets, List<VolleyballEvent> events})> getVolleyballData(String matchId) async {
    try {
      final idToken = await _cognito.getIdToken();
      return _matchApi.getVolleyballData(idToken, matchId);
    } on MatchException {
      rethrow;
    } on Exception {
      throw const MatchException('Error al obtener datos del partido. Intenta de nuevo.');
    }
  }
}
