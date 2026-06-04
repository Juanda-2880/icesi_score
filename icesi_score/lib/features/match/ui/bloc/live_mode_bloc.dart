import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/exceptions/match_exception.dart';
import '../../domain/usecases/end_match_period_usecase.dart';
import '../../domain/usecases/finish_match_usecase.dart';
import '../../domain/usecases/get_match_lineup_usecase.dart';
import '../../domain/usecases/get_match_periods_usecase.dart';
import '../../domain/usecases/get_soccer_events_usecase.dart';
import '../../domain/usecases/post_match_period_usecase.dart';
import '../../domain/usecases/post_soccer_event_usecase.dart';
import 'live_mode_event.dart';
import 'live_mode_state.dart';

class LiveModeBloc extends Bloc<LiveModeEvent, LiveModeState> {
  final GetMatchLineupUseCase _getLineup;
  final PostSoccerEventUseCase _postEvent;
  final GetSoccerEventsUseCase _getEvents;
  final GetMatchPeriodsUseCase _getMatchPeriods;
  final PostMatchPeriodUseCase _postMatchPeriod;
  final EndMatchPeriodUseCase _endMatchPeriod;
  final FinishMatchUseCase _finishMatch;

  Match? _currentMatch;

  LiveModeBloc(
    this._getLineup,
    this._postEvent,
    this._getEvents,
    this._getMatchPeriods,
    this._postMatchPeriod,
    this._endMatchPeriod,
    this._finishMatch,
  ) : super(const LiveModeLoadingState()) {
    on<LiveModeStartedEvent>(_onStarted);
    on<LiveModeEventSubmittedEvent>(_onEventSubmitted);
    on<LiveModeWsEventReceivedEvent>(_onWsEvent, transformer: sequential());
    on<StartPeriodEvent>(_onStartPeriod);
    on<EndPeriodEvent>(_onEndPeriod);
    on<FinishMatchEvent>(_onFinishMatch);
  }

  Future<void> _onStarted(
    LiveModeStartedEvent event,
    Emitter<LiveModeState> emit,
  ) async {
    _currentMatch = event.match;
    emit(const LiveModeLoadingState());
    try {
      final rawLineup = await _getLineup(event.match.id);
      final lineup = List<LineupPlayer>.from(rawLineup)
        ..sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));
      final events = await _getEvents(event.match.id);
      final periodsResult = await _getMatchPeriods(event.match.id);
      emit(LiveModeLoadedState(
        match: event.match,
        lineup: lineup,
        events: events,
        activePeriod: periodsResult.activePeriod,
        closedPeriodLabels: periodsResult.closedPeriodLabels,
        homeScore: event.match.homeScore ?? 0,
        awayScore: event.match.awayScore ?? 0,
      ));
    } on MatchException catch (e) {
      emit(LiveModeErrorState(e.message));
    } on Exception {
      emit(const LiveModeErrorState('Error al cargar el partido.'));
    }
  }

  Future<void> _onEventSubmitted(
    LiveModeEventSubmittedEvent event,
    Emitter<LiveModeState> emit,
  ) async {
    final current = state;
    if (current is! LiveModeLoadedState) return;
    emit(current.copyWith(isSubmitting: true));
    try {
      final result = await _postEvent(
        matchId: _currentMatch!.id,
        eventType: event.eventType,
        mainPlayerId: event.mainPlayerId,
        eventMinute: event.eventMinute,
        secondaryPlayerId: event.secondaryPlayerId,
        parentEventId: event.parentEventId,
        assistPlayerId: event.assistPlayerId,
        note: event.note,
      );

      var newLineup = List<LineupPlayer>.from(current.lineup);
      if (event.eventType == 'RED_CARD') {
        newLineup = newLineup
            .map((p) => p.playerId == event.mainPlayerId
                ? p.copyWith(status: 'EXPELLED')
                : p)
            .toList();
      } else if (event.eventType == 'SUBSTITUTION') {
        final outIdx =
            newLineup.indexWhere((p) => p.playerId == event.mainPlayerId);
        final inIdx = newLineup
            .indexWhere((p) => p.playerId == event.secondaryPlayerId);
        if (outIdx >= 0 && inIdx >= 0) {
          // Swap list positions so player_in inherits player_out's field slot.
          final playerOut = newLineup[outIdx].copyWith(status: 'ON_BENCH');
          final playerIn = newLineup[inIdx].copyWith(status: 'ON_FIELD');
          newLineup[outIdx] = playerIn;
          newLineup[inIdx] = playerOut;
        }
      }

      final refreshedEvents = await _getEvents(_currentMatch!.id);

      emit(LiveModeSubmitSuccessState(_successMessage(event.eventType)));
      emit(current.copyWith(
        lineup: newLineup,
        events: refreshedEvents,
        homeScore: result.homeScore,
        awayScore: result.awayScore,
        isSubmitting: false,
      ));
    } on MatchException catch (e) {
      emit(LiveModeSubmitErrorState(e.message));
      emit(current.copyWith(isSubmitting: false));
    } on Exception {
      emit(const LiveModeSubmitErrorState('Error inesperado al registrar el evento.'));
      emit(current.copyWith(isSubmitting: false));
    }
  }

  Future<void> _onWsEvent(
    LiveModeWsEventReceivedEvent event,
    Emitter<LiveModeState> emit,
  ) async {
    final current = state;
    if (current is! LiveModeLoadedState) return;

    int homeScore = current.homeScore;
    int awayScore = current.awayScore;
    final newScore = event.wsMessage['newScore'] as Map<String, dynamic>?;
    if (newScore != null) {
      homeScore = (newScore['homeScore'] as int?) ?? current.homeScore;
      awayScore = (newScore['awayScore'] as int?) ?? current.awayScore;
    }

    final eventData = event.wsMessage['event'] as Map<String, dynamic>?;
    var newLineup = List<LineupPlayer>.from(current.lineup);
    if (eventData != null) {
      final eventType = eventData['eventType'] as String?;
      if (eventType == 'SUBSTITUTION') {
        final outId = eventData['mainPlayerId'] as String?;
        final inId  = eventData['secondaryPlayerId'] as String?;
        if (outId != null && inId != null) {
          final outIdx = newLineup.indexWhere((p) => p.playerId == outId);
          final inIdx  = newLineup.indexWhere((p) => p.playerId == inId);
          if (outIdx >= 0 && inIdx >= 0) {
            // Swap list positions — field widget uses index, not coordinate.
            final playerOut = newLineup[outIdx].copyWith(status: 'ON_BENCH');
            final playerIn  = newLineup[inIdx].copyWith(status: 'ON_FIELD');
            newLineup[outIdx] = playerIn;
            newLineup[inIdx]  = playerOut;
          }
        }
      } else if (eventType == 'RED_CARD') {
        final expelledId = eventData['mainPlayerId'] as String?;
        if (expelledId != null) {
          newLineup = newLineup
              .map((p) => p.playerId == expelledId
                  ? p.copyWith(status: 'EXPELLED')
                  : p)
              .toList();
        }
      }
    }

    final msgType = event.wsMessage['type'] as String?;

    if (msgType == 'CLOCK_UPDATE') {
      final action = event.wsMessage['action'] as String?;

      if (action == 'START') {
        final newPeriod = MatchPeriod(
          id: event.wsMessage['periodId'] as String? ?? '',
          periodLabel: event.wsMessage['periodLabel'] as String? ?? '',
          startTime: DateTime.now(),
        );
        emit(current.copyWith(activePeriod: newPeriod, isSubmitting: false));
        return;
      }

      if (action == 'END') {
        final endedLabel = event.wsMessage['periodLabel'] as String?;
        final updated = List<String>.from(current.closedPeriodLabels);
        if (endedLabel != null && !updated.contains(endedLabel)) {
          updated.add(endedLabel);
        }
        emit(current.copyWith(
          clearActivePeriod: true,
          closedPeriodLabels: updated,
          isSubmitting: false,
        ));
        return;
      }

      if (action == 'FINISH') {
        final updatedMatch = current.match.copyWith(status: 'FINISHED');
        emit(current.copyWith(
          match: updatedMatch,
          clearActivePeriod: true,
          isSubmitting: false,
        ));
        return;
      }
    }

    try {
      // One extra HTTP call per external WS event — known limitation when
      // two admins operate the same match simultaneously.
      final refreshedEvents = await _getEvents(_currentMatch!.id);
      emit(current.copyWith(
        homeScore: homeScore,
        awayScore: awayScore,
        events: refreshedEvents,
        lineup: newLineup,
        isSubmitting: false,
      ));
    } catch (_) {
      emit(current.copyWith(
        homeScore: homeScore,
        awayScore: awayScore,
        lineup: newLineup,
        isSubmitting: false,
      ));
    }
  }

  Future<void> _onStartPeriod(
    StartPeriodEvent event,
    Emitter<LiveModeState> emit,
  ) async {
    final current = state;
    if (current is! LiveModeLoadedState) return;
    emit(current.copyWith(isSubmitting: true));
    try {
      final serverPeriod = await _postMatchPeriod(
        matchId: _currentMatch!.id,
        periodLabel: event.periodLabel,
      );
      // Use local time as startTime so the admin clock reads 00:00 immediately.
      // The DB stores the real server timestamp; this only affects the display.
      final period = MatchPeriod(
        id: serverPeriod.id,
        periodLabel: serverPeriod.periodLabel,
        startTime: DateTime.now(),
      );
      final updatedMatch = current.match.copyWith(status: 'IN_PROGRESS');
      _currentMatch = updatedMatch;
      emit(LiveModeSubmitSuccessState(
          '${event.periodLabel == '1T' ? 'Primer' : 'Segundo'} tiempo iniciado'));
      emit(current.copyWith(
        match: updatedMatch,
        activePeriod: period,
        isSubmitting: false,
      ));
    } on MatchException catch (e) {
      emit(LiveModeSubmitErrorState(e.message));
      emit(current.copyWith(isSubmitting: false));
    } on Exception {
      emit(const LiveModeSubmitErrorState('Error al iniciar el período.'));
      emit(current.copyWith(isSubmitting: false));
    }
  }

  Future<void> _onEndPeriod(
    EndPeriodEvent event,
    Emitter<LiveModeState> emit,
  ) async {
    final current = state;
    if (current is! LiveModeLoadedState) return;
    emit(current.copyWith(isSubmitting: true));
    try {
      await _endMatchPeriod(event.periodId);
      final closedLabel = current.activePeriod?.periodLabel ?? '';
      final updatedClosed = [...current.closedPeriodLabels, closedLabel];
      emit(LiveModeSubmitSuccessState(
          'Tiempo finalizado'));
      emit(current.copyWith(
        closedPeriodLabels: updatedClosed,
        clearActivePeriod: true,
        isSubmitting: false,
      ));
    } on MatchException catch (e) {
      emit(LiveModeSubmitErrorState(e.message));
      emit(current.copyWith(isSubmitting: false));
    } on Exception {
      emit(const LiveModeSubmitErrorState('Error al finalizar el período.'));
      emit(current.copyWith(isSubmitting: false));
    }
  }

  Future<void> _onFinishMatch(
    FinishMatchEvent event,
    Emitter<LiveModeState> emit,
  ) async {
    final current = state;
    if (current is! LiveModeLoadedState) return;
    emit(current.copyWith(isSubmitting: true));
    try {
      await _finishMatch(_currentMatch!.id);
      final updatedMatch = current.match.copyWith(status: 'FINISHED');
      _currentMatch = updatedMatch;
      emit(const LiveModeSubmitSuccessState('Partido finalizado'));
      emit(current.copyWith(
        match: updatedMatch,
        clearActivePeriod: true,
        isSubmitting: false,
      ));
    } on MatchException catch (e) {
      emit(LiveModeSubmitErrorState(e.message));
      emit(current.copyWith(isSubmitting: false));
    } on Exception {
      emit(const LiveModeSubmitErrorState('Error al finalizar el partido.'));
      emit(current.copyWith(isSubmitting: false));
    }
  }

  static String _successMessage(String eventType) {
    switch (eventType) {
      case 'GOAL':
        return 'Gol registrado';
      case 'ASSIST':
        return 'Asistencia registrada';
      case 'YELLOW_CARD':
        return 'Tarjeta amarilla registrada';
      case 'RED_CARD':
        return 'Tarjeta roja registrada. Jugador expulsado.';
      case 'SUBSTITUTION':
        return 'Sustitución registrada';
      case 'NOTE':
        return 'Nota guardada';
      default:
        return 'Evento registrado';
    }
  }
}
