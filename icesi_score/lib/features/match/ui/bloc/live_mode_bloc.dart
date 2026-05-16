import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match.dart';
import '../../domain/exceptions/match_exception.dart';
import '../../domain/usecases/get_match_lineup_usecase.dart';
import '../../domain/usecases/get_match_period_usecase.dart';
import '../../domain/usecases/get_soccer_events_usecase.dart';
import '../../domain/usecases/post_soccer_event_usecase.dart';
import 'live_mode_event.dart';
import 'live_mode_state.dart';

class LiveModeBloc extends Bloc<LiveModeEvent, LiveModeState> {
  final GetMatchLineupUseCase _getLineup;
  final PostSoccerEventUseCase _postEvent;
  final GetSoccerEventsUseCase _getEvents;
  final GetMatchPeriodUseCase _getPeriod;

  Match? _currentMatch;

  LiveModeBloc(
    this._getLineup,
    this._postEvent,
    this._getEvents,
    this._getPeriod,
  ) : super(const LiveModeLoadingState()) {
    on<LiveModeStartedEvent>(_onStarted);
    on<LiveModeEventSubmittedEvent>(_onEventSubmitted);
    on<LiveModeWsEventReceivedEvent>(_onWsEvent);
  }

  Future<void> _onStarted(
    LiveModeStartedEvent event,
    Emitter<LiveModeState> emit,
  ) async {
    _currentMatch = event.match;
    emit(const LiveModeLoadingState());
    try {
      final rawLineup = await _getLineup(event.match.id);
      // Sort once here so slot indices stay stable across substitutions.
      final lineup = List<LineupPlayer>.from(rawLineup)
        ..sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));
      final events = await _getEvents(event.match.id);
      final period = await _getPeriod(event.match.id);
      emit(LiveModeLoadedState(
        match: event.match,
        lineup: lineup,
        events: events,
        activePeriod: period,
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

  void _onWsEvent(
    LiveModeWsEventReceivedEvent event,
    Emitter<LiveModeState> emit,
  ) {
    final current = state;
    if (current is! LiveModeLoadedState) return;
    final newScore = event.wsMessage['newScore'] as Map<String, dynamic>?;
    if (newScore != null) {
      emit(current.copyWith(
        homeScore: (newScore['homeScore'] as int?) ?? current.homeScore,
        awayScore: (newScore['awayScore'] as int?) ?? current.awayScore,
      ));
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
