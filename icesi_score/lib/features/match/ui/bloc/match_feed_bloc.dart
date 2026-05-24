import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/match.dart';
import '../../domain/exceptions/match_exception.dart';
import '../../domain/usecases/get_matches_usecase.dart';
import 'match_feed_event.dart';
import 'match_feed_state.dart';

class MatchFeedBloc extends Bloc<MatchFeedEvent, MatchFeedState> {
  final GetMatchesUseCase _getMatches;
  final String _sport;
  List<Match> _allMatches = [];

  MatchFeedBloc(this._getMatches, this._sport)
    : super(const MatchFeedLoadingState()) {
    on<MatchFeedStartedEvent>(_onStarted);
    on<MatchFeedSearchChangedEvent>(_onSearchChanged);
  }

  Future<void> _onStarted(
    MatchFeedStartedEvent event,
    Emitter<MatchFeedState> emit,
  ) async {
    emit(const MatchFeedLoadingState());
    try {
      final matches = await _getMatches(_sport);
      _allMatches = matches;
      emit(MatchFeedLoadedState(matches));
    } on MatchException catch (e) {
      emit(MatchFeedErrorState(e.message));
    } on Exception {
      emit(const MatchFeedErrorState('Error al cargar los partidos.'));
    }
  }

  void _onSearchChanged(
    MatchFeedSearchChangedEvent event,
    Emitter<MatchFeedState> emit,
  ) {
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      emit(MatchFeedLoadedState(_allMatches));
      return;
    }

    final filteredMatches = _allMatches.where((match) {
      return match.homeTeamName.toLowerCase().contains(query) ||
          match.awayTeamName.toLowerCase().contains(query) ||
          match.leagueName.toLowerCase().contains(query);
    }).toList();

    emit(MatchFeedLoadedState(filteredMatches));
  }
}

class FootballFeedBloc extends MatchFeedBloc {
  FootballFeedBloc(GetMatchesUseCase uc) : super(uc, 'FOOTBALL');
}

class VolleyballFeedBloc extends MatchFeedBloc {
  VolleyballFeedBloc(GetMatchesUseCase uc) : super(uc, 'VOLLEYBALL');
}
