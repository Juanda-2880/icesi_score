import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../amplifyconfiguration.dart' show apiBaseUrl;
import '../../domain/entities/league.dart';
import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/entities/soccer_event.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/volleyball_event.dart';
import '../../domain/entities/volleyball_set.dart';
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
                mainPlayerId: e['mainPlayerId'] as String?,
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
    final result = await getMatchPeriods(idToken, matchId);
    return result.activePeriod;
  }

  @override
  Future<({MatchPeriod? activePeriod, List<String> closedPeriodLabels})>
      getMatchPeriods(String idToken, String matchId) async {
    final response = await _client.get(
      Uri.parse('$_kApiBase/matches/$matchId/periods'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      MatchPeriod? activePeriod;
      final closedLabels = <String>[];
      for (final item in list) {
        final e = item as Map<String, dynamic>;
        if (e['endTime'] == null) {
          activePeriod = MatchPeriod(
            id: e['id'] as String,
            periodLabel: e['periodLabel'] as String,
            startTime:
                DateTime.parse('${e['startTime'] as String}Z').toLocal(),
          );
        } else {
          closedLabels.add(e['periodLabel'] as String);
        }
      }
      return (activePeriod: activePeriod, closedPeriodLabels: closedLabels);
    }

    throw MatchException('Error al obtener períodos (${response.statusCode}).');
  }

  @override
  Future<MatchPeriod> postMatchPeriod({
    required String idToken,
    required String matchId,
    required String periodLabel,
  }) async {
    final response = await _client.post(
      Uri.parse('$_kApiBase/admin/match-periods'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'matchId': matchId, 'periodLabel': periodLabel}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MatchPeriod(
        id: data['id'] as String,
        periodLabel: data['periodLabel'] as String,
        startTime:
            DateTime.parse('${data['startTime'] as String}Z').toLocal(),
      );
    }
    if (response.statusCode == 409) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(decoded['error'] as String? ?? 'Conflicto al iniciar período.');
    }
    if (response.statusCode == 403) {
      throw const MatchException('Sin permisos para iniciar períodos.');
    }
    throw MatchException('Error al iniciar período (${response.statusCode}).');
  }

  @override
  Future<void> endMatchPeriod({
    required String idToken,
    required String periodId,
  }) async {
    final response = await _client.put(
      Uri.parse('$_kApiBase/admin/match-periods/$periodId'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) return;
    if (response.statusCode == 409) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(decoded['error'] as String? ?? 'El período ya está cerrado.');
    }
    if (response.statusCode == 403) {
      throw const MatchException('Sin permisos para cerrar períodos.');
    }
    throw MatchException('Error al cerrar período (${response.statusCode}).');
  }

  @override
  Future<void> finishMatch({
    required String idToken,
    required String matchId,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_kApiBase/admin/matches/$matchId/finish'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) return;
    if (response.statusCode == 409) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(decoded['error'] as String? ?? 'El partido no está en progreso.');
    }
    if (response.statusCode == 403) {
      throw const MatchException('Sin permisos para finalizar el partido.');
    }
    throw MatchException('Error al finalizar el partido (${response.statusCode}).');
  }

  @override
  Future<({List<VolleyballSet> sets, List<VolleyballEvent> events})> getVolleyballData(
    String idToken,
    String matchId,
  ) async {
    final response = await _client.get(
      Uri.parse('$_kApiBase/matches/$matchId/volleyball-data'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final sets = (data['sets'] as List<dynamic>)
          .map((e) => VolleyballSet(
                id: e['id'] as String,
                setNumber: e['setNumber'] as int,
                homeScore: e['homeScore'] as int,
                awayScore: e['awayScore'] as int,
                isActive: e['isActive'] as bool,
                endTime: e['endTime'] as String?,
              ))
          .toList();

      final events = (data['events'] as List<dynamic>)
          .map((e) => VolleyballEvent(
                id: e['id'] as String,
                setId: e['setId'] as String,
                setNumber: e['setNumber'] as int,
                eventType: e['eventType'] as String,
                playerName: e['playerName'] as String?,
                secondaryPlayerName: e['secondaryPlayerName'] as String?,
                teamId: e['teamId'] as String?,
                teamName: e['teamName'] as String?,
                scoreMoment: e['scoreMoment'] as String?,
                note: e['note'] as String?,
              ))
          .toList();

      return (sets: sets, events: events);
    }

    throw MatchException('Error al obtener datos del partido (${response.statusCode}).');
  }

  @override
  Future<List<LineupPlayer>> getMatchLineup(String idToken, String matchId) async {
    final response = await _client.get(
      Uri.parse('$_kApiBase/matches/$matchId/lineup'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => LineupPlayer(
                id: e['id'] as String,
                playerId: e['playerId'] as String,
                playerName: e['playerName'] as String,
                jerseyNumber: e['jerseyNumber'] as int,
                teamId: e['teamId'] as String,
                teamName: e['teamName'] as String,
                status: e['status'] as String,
                positionCoordinate: e['positionCoordinate'] as String?,
              ))
          .toList();
    }
    throw MatchException('Error al obtener alineación (${response.statusCode}).');
  }

  @override
  Future<VolleyballSet> postVolleyballSet({
    required String idToken,
    required String matchId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_kApiBase/admin/volleyball-sets'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'matchId': matchId}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return VolleyballSet(
        id: data['id'] as String,
        setNumber: data['setNumber'] as int,
        homeScore: data['homeScore'] as int,
        awayScore: data['awayScore'] as int,
        isActive: data['isActive'] as bool,
      );
    }
    if (response.statusCode == 409) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(decoded['error'] as String? ?? 'Conflicto al iniciar set.');
    }
    if (response.statusCode == 403) {
      throw const MatchException('Sin permisos para iniciar sets.');
    }
    throw MatchException('Error al iniciar set (${response.statusCode}).');
  }

  @override
  Future<({
    VolleyballEvent event,
    int homeSetScore,
    int awaySetScore,
    int homeSets,
    int awaySets,
    bool setComplete,
    bool matchFinished,
  })> postVolleyballEvent({
    required String idToken,
    required String setId,
    required String eventType,
    required String teamId,
    String? mainPlayerId,
    String? secondaryPlayerId,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'setId': setId,
      'eventType': eventType,
      'teamId': teamId,
    };
    if (mainPlayerId != null) body['mainPlayerId'] = mainPlayerId;
    if (secondaryPlayerId != null) body['secondaryPlayerId'] = secondaryPlayerId;
    if (note != null && note.isNotEmpty) body['note'] = note;

    final response = await _client.post(
      Uri.parse('$_kApiBase/admin/volleyball-events'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final e = data['event'] as Map<String, dynamic>;
      final setScore = data['setScore'] as Map<String, dynamic>;
      final matchScore = data['matchScore'] as Map<String, dynamic>;
      return (
        event: VolleyballEvent(
          id: e['id'] as String,
          setId: setId,
          setNumber: 0,
          eventType: e['eventType'] as String,
          playerName: e['playerName'] as String?,
          secondaryPlayerName: e['secondaryPlayerName'] as String?,
          teamId: e['teamId'] as String?,
          scoreMoment: e['scoreMoment'] as String?,
          note: e['note'] as String?,
        ),
        homeSetScore: setScore['homeScore'] as int,
        awaySetScore: setScore['awayScore'] as int,
        homeSets: matchScore['homeSets'] as int,
        awaySets: matchScore['awaySets'] as int,
        setComplete: data['setComplete'] as bool,
        matchFinished: data['matchFinished'] as bool,
      );
    }
    if (response.statusCode == 403) {
      throw const MatchException('Sin permisos para registrar eventos.');
    }
    if (response.statusCode == 409) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(decoded['error'] as String? ?? 'El set no está activo.');
    }
    throw MatchException('Error al registrar evento (${response.statusCode}).');
  }

  @override
  Future<List<LineupPlayer>> rotateTeam({
    required String idToken,
    required String matchId,
    required String teamId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_kApiBase/admin/matches/$matchId/rotate-team'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'teamId': teamId}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['lineup'] as List<dynamic>;
      return list
          .map((e) => LineupPlayer(
                id: '',
                playerId: e['playerId'] as String,
                playerName: '',
                jerseyNumber: 0,
                teamId: teamId,
                teamName: '',
                status: 'ON_FIELD',
                positionCoordinate: e['positionCoordinate'] as String?,
              ))
          .toList();
    }
    if (response.statusCode == 403) {
      throw const MatchException('Sin permisos para rotar equipo.');
    }
    if (response.statusCode == 409) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(decoded['error'] as String? ?? 'No hay set activo.');
    }
    throw MatchException('Error al rotar equipo (${response.statusCode}).');
  }

  @override
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
  }) async {
    final body = <String, dynamic>{
      'eventType': eventType,
      'mainPlayerId': mainPlayerId,
      'eventMinute': eventMinute,
    };
    if (secondaryPlayerId != null) body['secondaryPlayerId'] = secondaryPlayerId;
    if (parentEventId != null) body['parentEventId'] = parentEventId;
    if (assistPlayerId != null) body['assistPlayerId'] = assistPlayerId;
    if (note != null && note.isNotEmpty) body['note'] = note;
    final response = await _client.post(
      Uri.parse('$_kApiBase/matches/$matchId/soccer-events'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final e = data['event'] as Map<String, dynamic>;
      final s = data['newScore'] as Map<String, dynamic>;
      return (
        event: SoccerEvent(
          id: e['id'] as String,
          matchId: matchId,
          eventType: e['eventType'] as String,
          minute: e['minute'] as int,
          playerName: e['playerName'] as String?,
          teamId: e['teamId'] as String?,
          scoreAtMoment: e['scoreAtMoment'] as String?,
          parentEventId: e['parentEventId'] as String?,
          note: e['note'] as String?,
        ),
        homeScore: s['homeScore'] as int,
        awayScore: s['awayScore'] as int,
      );
    }
    if (response.statusCode == 403) {
      throw const MatchException('Sin permisos para registrar eventos.');
    }
    if (response.statusCode == 409) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw MatchException(decoded['error'] as String? ?? 'El partido no está en progreso.');
    }
    throw MatchException('Error al registrar evento (${response.statusCode}).');
  }
}
