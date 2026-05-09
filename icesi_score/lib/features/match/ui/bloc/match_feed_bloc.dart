import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/exceptions/match_exception.dart';
import '../../domain/usecases/get_matches_usecase.dart';
import 'match_feed_event.dart';
import 'match_feed_state.dart';

class MatchFeedBloc extends Bloc<MatchFeedEvent, MatchFeedState> {
  final GetMatchesUseCase _getMatches;
  final String _sport;

  MatchFeedBloc(this._getMatches, this._sport)
      : super(const MatchFeedLoadingState()) {
    on<MatchFeedStartedEvent>(_onStarted);
  }

  Future<void> _onStarted(
    MatchFeedStartedEvent event,
    Emitter<MatchFeedState> emit,
  ) async {
    emit(const MatchFeedLoadingState());
    try {
      final matches = await _getMatches(_sport);
      emit(MatchFeedLoadedState(matches));
    } on MatchException catch (e) {
      emit(MatchFeedErrorState(e.message));
    } on Exception {
      emit(const MatchFeedErrorState('Error al cargar los partidos.'));
    }
  }
}

class FootballFeedBloc extends MatchFeedBloc {
  FootballFeedBloc(GetMatchesUseCase uc) : super(uc, 'FOOTBALL');
}

class VolleyballFeedBloc extends MatchFeedBloc {
  VolleyballFeedBloc(GetMatchesUseCase uc) : super(uc, 'VOLLEYBALL');
}
