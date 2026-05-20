import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/volleyball_event.dart';
import '../../domain/entities/volleyball_set.dart';
import '../../domain/exceptions/match_exception.dart';
import '../../domain/usecases/get_volleyball_data_usecase.dart';
import 'volleyball_detail_event.dart';
import 'volleyball_detail_state.dart';

class VolleyballDetailBloc
    extends Bloc<VolleyballDetailEvent, VolleyballDetailState> {
  final GetVolleyballDataUseCase _getVolleyballData;

  Match? _currentMatch;

  VolleyballDetailBloc(this._getVolleyballData)
      : super(const VolleyballDetailLoadingState()) {
    on<VolleyballDetailStartedEvent>(_onStarted);
    on<VolleyballDetailRefreshRequestedEvent>(_onRefresh);
    on<VolleyballEventReceivedEvent>(_onEventReceived);
    on<VolleyballDetailWsEventReceivedEvent>(_onWsEvent);
  }

  Future<void> _onStarted(
    VolleyballDetailStartedEvent event,
    Emitter<VolleyballDetailState> emit,
  ) async {
    _currentMatch = event.match;
    emit(const VolleyballDetailLoadingState());
    await _loadData(event.match, emit);
  }

  Future<void> _onRefresh(
    VolleyballDetailRefreshRequestedEvent event,
    Emitter<VolleyballDetailState> emit,
  ) async {
    if (_currentMatch == null) return;
    await _loadData(_currentMatch!, emit);
  }

  Future<void> _loadData(Match match, Emitter<VolleyballDetailState> emit) async {
    try {
      final (:sets, :events) = await _getVolleyballData(match.id);
      emit(VolleyballDetailLoadedState(match: match, sets: sets, events: events));
    } on MatchException catch (e) {
      emit(VolleyballDetailErrorState(e.message));
    } on Exception {
      emit(const VolleyballDetailErrorState('Ocurrió un error inesperado.'));
    }
  }

  void _onEventReceived(
    VolleyballEventReceivedEvent event,
    Emitter<VolleyballDetailState> emit,
  ) {
    final current = state;
    if (current is! VolleyballDetailLoadedState) return;
    final updated = <VolleyballEvent>[event.event, ...current.events];
    emit(VolleyballDetailLoadedState(
      match: current.match,
      sets: current.sets,
      events: updated,
    ));
  }

  Future<void> _onWsEvent(
    VolleyballDetailWsEventReceivedEvent event,
    Emitter<VolleyballDetailState> emit,
  ) async {
    final current = state;
    if (current is! VolleyballDetailLoadedState) return;

    final setComplete = event.wsMessage['setComplete'] == true;
    final matchFinished = event.wsMessage['matchFinished'] == true;

    if (setComplete || matchFinished) {
      // Update _currentMatch with new sets-won counts from WS payload before refresh,
      // so _loadData emits the correct match header score.
      final matchScoreRaw =
          event.wsMessage['matchScore'] as Map<String, dynamic>?;
      if (matchScoreRaw != null) {
        _currentMatch = current.match.copyWith(
          homeScore: (matchScoreRaw['homeSets'] as int?) ??
              current.match.homeScore,
          awayScore: (matchScoreRaw['awaySets'] as int?) ??
              current.match.awayScore,
          status: matchFinished ? 'FINISHED' : current.match.status,
        );
      }
      if (_currentMatch != null) {
        await _loadData(_currentMatch!, emit);
      }
      return;
    }

    // Incremental: update active set score and prepend new event.
    final setScoreRaw =
        event.wsMessage['setScore'] as Map<String, dynamic>?;
    final eventRaw = event.wsMessage['event'] as Map<String, dynamic>?;

    final updatedSets = setScoreRaw != null
        ? current.sets.map((s) {
            if (s.isActive) {
              return s.copyWithScores(
                homeScore:
                    (setScoreRaw['homeScore'] as int?) ?? s.homeScore,
                awayScore:
                    (setScoreRaw['awayScore'] as int?) ?? s.awayScore,
              );
            }
            return s;
          }).toList()
        : current.sets;

    var updatedEvents = current.events;
    if (eventRaw != null) {
      final activeSetNumber = current.sets.firstWhere(
        (s) => s.isActive,
        orElse: () => const VolleyballSet(
          id: '',
          setNumber: 0,
          homeScore: 0,
          awayScore: 0,
          isActive: false,
        ),
      ).setNumber;
      final teamId = eventRaw['teamId'] as String?;
      final teamName = teamId == null
          ? null
          : (teamId == current.match.homeTeamId
              ? current.match.homeTeamName
              : current.match.awayTeamName);
      final newEvent = VolleyballEvent(
        id: (eventRaw['id'] as String?) ?? '',
        setId: (eventRaw['setId'] as String?) ?? '',
        setNumber: (eventRaw['setNumber'] as int?) ?? activeSetNumber,
        eventType: (eventRaw['eventType'] as String?) ?? '',
        playerName: eventRaw['playerName'] as String?,
        secondaryPlayerName: eventRaw['secondaryPlayerName'] as String?,
        teamId: teamId,
        teamName: teamName,
        scoreMoment: eventRaw['scoreMoment'] as String?,
        note: eventRaw['note'] as String?,
      );
      updatedEvents = [newEvent, ...current.events];
    }

    emit(VolleyballDetailLoadedState(
      match: current.match,
      sets: updatedSets,
      events: updatedEvents,
    ));
  }
}
