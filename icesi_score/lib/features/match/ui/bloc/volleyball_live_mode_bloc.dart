import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/volleyball_set.dart';
import '../../domain/exceptions/match_exception.dart';
import '../../domain/usecases/get_match_lineup_usecase.dart';
import '../../domain/usecases/get_volleyball_data_usecase.dart';
import '../../domain/usecases/post_volleyball_event_usecase.dart';
import '../../domain/usecases/post_volleyball_set_usecase.dart';
import '../../domain/usecases/rotate_team_usecase.dart';
import 'volleyball_live_mode_event.dart';
import 'volleyball_live_mode_state.dart';

class VolleyballLiveModeBloc
    extends Bloc<VolleyballLiveModeEvent, VolleyballLiveModeState> {
  final GetMatchLineupUseCase _getLineup;
  final GetVolleyballDataUseCase _getVolleyballData;
  final PostVolleyballSetUseCase _postSet;
  final PostVolleyballEventUseCase _postEvent;
  final RotateTeamUseCase _rotateTeam;

  Match? _currentMatch;

  VolleyballLiveModeBloc(
    this._getLineup,
    this._getVolleyballData,
    this._postSet,
    this._postEvent,
    this._rotateTeam,
  ) : super(const VolleyballLiveModeLoadingState()) {
    on<VolleyballLiveModeStartedEvent>(_onStarted);
    on<StartSetEvent>(_onStartSet);
    on<VolleyballEventSubmittedEvent>(_onEventSubmitted);
    on<RotateTeamEvent>(_onRotateTeam);
  }

  Future<void> _onStarted(
    VolleyballLiveModeStartedEvent event,
    Emitter<VolleyballLiveModeState> emit,
  ) async {
    _currentMatch = event.match;
    emit(const VolleyballLiveModeLoadingState());
    try {
      final rawLineup = await _getLineup(event.match.id);
      final lineup = List<LineupPlayer>.from(rawLineup)
        ..sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));
      final (:sets, :events) = await _getVolleyballData(event.match.id);
      final activeSet = sets.where((s) => s.isActive).firstOrNull;
      final closedSets = sets.where((s) => !s.isActive).toList();
      emit(VolleyballLiveModeLoadedState(
        match: event.match,
        lineup: lineup,
        activeSet: activeSet,
        closedSets: closedSets,
        recentEvents: events,
      ));
    } on MatchException catch (e) {
      emit(VolleyballLiveModeErrorState(e.message));
    } on Exception {
      emit(const VolleyballLiveModeErrorState('Error al cargar el partido.'));
    }
  }

  Future<void> _onStartSet(
    StartSetEvent event,
    Emitter<VolleyballLiveModeState> emit,
  ) async {
    final current = state;
    if (current is! VolleyballLiveModeLoadedState) return;
    emit(current.copyWith(isSubmitting: true));
    try {
      final newSet = await _postSet(matchId: _currentMatch!.id);
      final updatedMatch = current.match.copyWith(status: 'IN_PROGRESS');
      _currentMatch = updatedMatch;
      emit(VolleyballLiveModeSubmitSuccessState('Set ${newSet.setNumber} iniciado'));
      emit(current.copyWith(
        match: updatedMatch,
        activeSet: newSet,
        isSubmitting: false,
      ));
    } on MatchException catch (e) {
      emit(VolleyballLiveModeSubmitErrorState(e.message));
      emit(current.copyWith(isSubmitting: false));
    } on Exception {
      emit(const VolleyballLiveModeSubmitErrorState('Error al iniciar el set.'));
      emit(current.copyWith(isSubmitting: false));
    }
  }

  Future<void> _onEventSubmitted(
    VolleyballEventSubmittedEvent event,
    Emitter<VolleyballLiveModeState> emit,
  ) async {
    final current = state;
    if (current is! VolleyballLiveModeLoadedState) return;
    if (current.activeSet == null) return;
    emit(current.copyWith(isSubmitting: true));
    try {
      final result = await _postEvent(
        setId: current.activeSet!.id,
        eventType: event.eventType,
        teamId: event.teamId,
        mainPlayerId: event.mainPlayerId,
        secondaryPlayerId: event.secondaryPlayerId,
        note: event.note,
      );

      // Update lineup locally for substitutions
      var newLineup = List<LineupPlayer>.from(current.lineup);
      if (event.eventType == 'SUBSTITUTION' &&
          event.mainPlayerId != null &&
          event.secondaryPlayerId != null) {
        final outIdx = newLineup.indexWhere((p) => p.playerId == event.mainPlayerId);
        final inIdx = newLineup.indexWhere((p) => p.playerId == event.secondaryPlayerId);
        if (outIdx >= 0 && inIdx >= 0) {
          final outPos = newLineup[outIdx].positionCoordinate;
          newLineup[outIdx] = newLineup[outIdx].copyWith(status: 'ON_BENCH');
          newLineup[inIdx] = newLineup[inIdx]
              .copyWith(status: 'ON_FIELD', positionCoordinate: outPos);
        }
      }

      // Update set score locally
      final updatedActiveSet = result.setComplete
          ? null
          : current.activeSet!.copyWithScores(
              homeScore: result.homeSetScore,
              awayScore: result.awaySetScore,
            );

      var newClosedSets = List<VolleyballSet>.from(current.closedSets);
      if (result.setComplete) {
        newClosedSets = [
          ...newClosedSets,
          current.activeSet!.copyWithScores(
            homeScore: result.homeSetScore,
            awayScore: result.awaySetScore,
          ),
        ];
      }

      // Update match sets score
      var updatedMatch = current.match.copyWith(
        homeScore: result.homeSets,
        awayScore: result.awaySets,
      );
      if (result.matchFinished) {
        updatedMatch = updatedMatch.copyWith(status: 'FINISHED');
        _currentMatch = updatedMatch;
      }

      final updatedEvents = [result.event, ...current.recentEvents];

      emit(VolleyballLiveModeSubmitSuccessState(_successMessage(event.eventType)));
      emit(current.copyWith(
        match: updatedMatch,
        lineup: newLineup,
        activeSet: updatedActiveSet,
        closedSets: newClosedSets,
        recentEvents: updatedEvents,
        isSubmitting: false,
        clearActiveSet: result.setComplete,
      ));
    } on MatchException catch (e) {
      emit(VolleyballLiveModeSubmitErrorState(e.message));
      emit(current.copyWith(isSubmitting: false));
    } on Exception {
      emit(const VolleyballLiveModeSubmitErrorState('Error inesperado al registrar el evento.'));
      emit(current.copyWith(isSubmitting: false));
    }
  }

  Future<void> _onRotateTeam(
    RotateTeamEvent event,
    Emitter<VolleyballLiveModeState> emit,
  ) async {
    final current = state;
    if (current is! VolleyballLiveModeLoadedState) return;
    emit(current.copyWith(isSubmitting: true));
    try {
      final updatedPositions = await _rotateTeam(
        matchId: _currentMatch!.id,
        teamId: event.teamId,
      );
      // Merge updated positions back into the full lineup
      final posMap = {for (final p in updatedPositions) p.playerId: p.positionCoordinate};
      final newLineup = current.lineup.map((p) {
        final newPos = posMap[p.playerId];
        return newPos != null ? p.copyWith(positionCoordinate: newPos) : p;
      }).toList();

      emit(VolleyballLiveModeSubmitSuccessState('Rotación registrada'));
      emit(current.copyWith(lineup: newLineup, isSubmitting: false));
    } on MatchException catch (e) {
      emit(VolleyballLiveModeSubmitErrorState(e.message));
      emit(current.copyWith(isSubmitting: false));
    } on Exception {
      emit(const VolleyballLiveModeSubmitErrorState('Error al rotar el equipo.'));
      emit(current.copyWith(isSubmitting: false));
    }
  }

  static String _successMessage(String eventType) {
    switch (eventType) {
      case 'POINT':
        return 'Punto registrado';
      case 'SERVICE_ACE':
        return 'Ace de servicio registrado';
      case 'BLOCK':
        return 'Bloqueo registrado';
      case 'ROTATION_FAULT':
        return 'Falta de rotación registrada';
      case 'SUBSTITUTION':
        return 'Sustitución registrada';
      case 'NOTE':
        return 'Nota guardada';
      default:
        return 'Evento registrado';
    }
  }
}
