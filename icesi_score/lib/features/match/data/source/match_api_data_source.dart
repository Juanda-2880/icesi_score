import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../amplifyconfiguration.dart' show apiBaseUrl;
import '../../domain/entities/league.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/entities/soccer_event.dart';
import '../../domain/entities/team.dart';
import '../../domain/exceptions/match_exception.dart';
import 'match_data_source.dart';

const _kApiBase = apiBaseUrl;

class MatchApiDataSource implements MatchDataSource {
  final http.Client _client;

  MatchApiDataSource([http.Client? client]) : _client = client ?? http.Client();

  @override
  Future<List<Team>> getTeams(String idToken) async {
    final response = await _client.get(
      Uri.parse('$_kApiBase/teams'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => Team(
                id: e['id'] as String,
                name: e['name'] as String,
                sport: e['sport'] as String,
              ))
          .toList();
    }

    throw MatchException('Error al obtener equipos (${response.statusCode}).');
  }

  @override
  Future<List<League>> getLeagues(String idToken) async {
    final response = await _client.get(
      Uri.parse('$_kApiBase/leagues'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => League(
                id: e['id'] as String,
                name: e['name'] as String,
              ))
          .toList();
    }

    throw MatchException('Error al obtener ligas (${response.statusCode}).');
  }

  @override
  Future<List<Match>> getMatches(String idToken, String sport) async {
    final response = await _client.get(
      Uri.parse('$_kApiBase/matches?sport=$sport'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => Match(
                id: e['id'] as String,
                sport: e['sport'] as String,
                status: e['status'] as String,
                matchDate: e['matchDate'] as String?,
                matchTime: e['matchTime'] as String?,
                venue: e['venue'] as String?,
                homeScore: e['homeScore'] as int?,
                awayScore: e['awayScore'] as int?,
                homeTeamId: e['homeTeamId'] as String,
                homeTeamName: e['homeTeamName'] as String,
                awayTeamId: e['awayTeamId'] as String,
                awayTeamName: e['awayTeamName'] as String,
                leagueId: e['leagueId'] as String,
                leagueName: e['leagueName'] as String,
                notes: e['notes'] as String?,
              ))
          .toList();
    }

    throw MatchException('Error al obtener partidos (${response.statusCode}).');
  }

  @override
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
  }) async {
    final body = <String, dynamic>{
      'sport': sport,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'leagueId': leagueId,
      'matchDate': matchDate,
      'matchTime': matchTime,
      'venue': venue,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await _client.post(
      Uri.parse('$_kApiBase/admin/matches'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) return;

    if (response.statusCode == 400) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(
          decoded['error'] as String? ?? 'Datos inválidos.');
    }
    if (response.statusCode == 403) {
      throw const MatchException('No tienes permisos para crear partidos.');
    }
    if (response.statusCode == 409) {
      throw const MatchException(
          'Conflicto: ya existe un partido con esa configuración.');
    }

    throw const MatchException('Error al crear el partido. Intenta de nuevo.');
  }

  @override
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
  }) async {
    final body = <String, dynamic>{
      'sport': sport,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'leagueId': leagueId,
      'matchDate': matchDate,
      'matchTime': matchTime,
      'venue': venue,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await _client.put(
      Uri.parse('$_kApiBase/admin/matches/$id'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) return;

    if (response.statusCode == 400 || response.statusCode == 409) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(decoded['error'] as String? ?? 'Datos inválidos.');
    }
    if (response.statusCode == 403) {
      throw const MatchException('No tienes permisos para editar partidos.');
    }

    throw const MatchException('Error al editar el partido. Intenta de nuevo.');
  }

  @override
  Future<void> deleteMatch({required String idToken, required String id}) async {
    final response = await _client.delete(
      Uri.parse('$_kApiBase/admin/matches/$id'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) return;

    if (response.statusCode == 409) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(decoded['error'] as String? ?? 'El partido no puede eliminarse.');
    }
    if (response.statusCode == 403) {
      throw const MatchException('No tienes permisos para eliminar partidos.');
    }

    throw const MatchException('Error al eliminar el partido. Intenta de nuevo.');
  }

  @override
  Future<List<SoccerEvent>> getSoccerEvents(String idToken, String matchId) async {
    final response = await _client.get(
      Uri.parse('$_kApiBase/matches/$matchId/soccer-events'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => SoccerEvent(
                id: e['id'] as String,
                matchId: matchId,
                eventType: e['eventType'] as String,
                minute: e['minute'] as int,
                playerName: e['playerName'] as String?,
                teamId: e['teamId'] as String?,
                teamName: e['teamName'] as String?,
                scoreAtMoment: e['scoreAtMoment'] as String?,
                parentEventId: e['parentEventId'] as String?,
                secondaryPlayerName: e['secondaryPlayerName'] as String?,
              ))
          .toList();
    }

    throw MatchException('Error al obtener eventos (${response.statusCode}).');
  }

  @override
  Future<MatchPeriod?> getActivePeriod(String idToken, String matchId) async {
    final response = await _client.get(
      Uri.parse('$_kApiBase/matches/$matchId/periods'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MatchPeriod(
        id: data['id'] as String,
        periodLabel: data['periodLabel'] as String,
        startTime: DateTime.parse('${data['startTime'] as String}Z').toLocal(),
      );
    }

    if (response.statusCode == 404) return null;

    throw MatchException('Error al obtener período (${response.statusCode}).');
  }
}
