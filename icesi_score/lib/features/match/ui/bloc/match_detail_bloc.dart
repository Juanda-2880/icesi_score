import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/exceptions/match_exception.dart';
import '../../domain/usecases/get_match_period_usecase.dart';
import '../../domain/usecases/get_soccer_events_usecase.dart';
import 'match_detail_event.dart';
import 'match_detail_state.dart';

class MatchDetailBloc extends Bloc<MatchDetailEvent, MatchDetailState> {
  final GetSoccerEventsUseCase _getSoccerEvents;
  final GetMatchPeriodUseCase _getActivePeriod;

  Match? _currentMatch;

  MatchDetailBloc(this._getSoccerEvents, this._getActivePeriod)
      : super(const MatchDetailLoadingState()) {
    on<MatchDetailStartedEvent>(_onStarted);
    on<MatchDetailRefreshRequestedEvent>(_onRefresh);
    on<MatchEventReceivedEvent>(_onEventReceived);
    on<MatchClockUpdateReceivedEvent>(_onClockUpdate);
  }

  Future<void> _onStarted(
    MatchDetailStartedEvent event,
    Emitter<MatchDetailState> emit,
  ) async {
    _currentMatch = event.match;
    emit(const MatchDetailLoadingState());
    await _loadData(event.match, emit);
  }

  Future<void> _onRefresh(
    MatchDetailRefreshRequestedEvent event,
    Emitter<MatchDetailState> emit,
  ) async {
    if (_currentMatch == null) return;
    await _loadData(_currentMatch!, emit);
  }

  Future<void> _loadData(Match match, Emitter<MatchDetailState> emit) async {
    try {
      final eventsF = _getSoccerEvents(match.id);
      final periodF = _getActivePeriod(match.id);
      final events = await eventsF;
      final period = await periodF;
      emit(MatchDetailLoadedState(
        match: match,
        events: events,
        activePeriod: period,
      ));
    } on MatchException catch (e) {
      emit(MatchDetailErrorState(e.message));
    } on Exception {
      emit(const MatchDetailErrorState('Ocurrió un error inesperado.'));
    }
  }

  void _onEventReceived(
    MatchEventReceivedEvent event,
    Emitter<MatchDetailState> emit,
  ) {
    final current = state;
    if (current is! MatchDetailLoadedState) return;
    if (event.newHomeScore != null || event.newAwayScore != null) {
      final updatedMatch = current.match.copyWith(
        homeScore: event.newHomeScore ?? current.match.homeScore,
        awayScore: event.newAwayScore ?? current.match.awayScore,
      );
      _currentMatch = updatedMatch;
      emit(current.copyWith(
        events: [event.event, ...current.events],
        match: updatedMatch,
      ));
    } else {
      emit(current.copyWith(
        events: [event.event, ...current.events],
      ));
    }
  }

  void _onClockUpdate(
    MatchClockUpdateReceivedEvent event,
    Emitter<MatchDetailState> emit,
  ) {
    final current = state;
    if (current is! MatchDetailLoadedState) return;

    switch (event.action) {
      case 'START':
        if (event.periodLabel == null) return;
        // Use local time so the fan clock reads 00:00 at the moment the WS
        // message arrives, not the server timestamp (which is already past).
        final newPeriod = MatchPeriod(
          id: event.periodId ?? '',
          periodLabel: event.periodLabel!,
          startTime: DateTime.now(),
        );
        final updatedMatch = current.match.copyWith(status: 'IN_PROGRESS');
        _currentMatch = updatedMatch;
        emit(current.copyWith(match: updatedMatch, activePeriod: newPeriod));

      case 'END':
        emit(current.copyWith(clearActivePeriod: true));

      case 'FINISH':
        final updatedMatch = current.match.copyWith(status: 'FINISHED');
        _currentMatch = updatedMatch;
        emit(current.copyWith(match: updatedMatch, clearActivePeriod: true));
    }
  }
}
