import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/volleyball_event.dart';
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
}
