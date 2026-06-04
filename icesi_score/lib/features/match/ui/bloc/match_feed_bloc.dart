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
  String _activeSearchQuery = '';
  String? _activeStatusFilter;

  MatchFeedBloc(this._getMatches, this._sport)
    : super(const MatchFeedLoadingState()) {
    on<MatchFeedStartedEvent>(_onStarted);
    on<MatchFeedSearchChangedEvent>(_onSearchChanged);
    on<MatchFeedStatusFilterChangedEvent>(_onStatusFilterChanged);
  }

  Future<void> _onStarted(
    MatchFeedStartedEvent event,
    Emitter<MatchFeedState> emit,
  ) async {
    emit(const MatchFeedLoadingState());
    try {
      final matches = await _getMatches(_sport);
      _allMatches = matches;
      emit(MatchFeedLoadedState(_applyActiveFilters()));
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
    _activeSearchQuery = event.query.toLowerCase();
    emit(MatchFeedLoadedState(_applyActiveFilters()));
  }

  void _onStatusFilterChanged(
    MatchFeedStatusFilterChangedEvent event,
    Emitter<MatchFeedState> emit,
  ) {
    _activeStatusFilter = event.status;
    emit(MatchFeedLoadedState(_applyActiveFilters()));
  }

  List<Match> _applyActiveFilters() {
    final query = _activeSearchQuery;

    return _allMatches.where((match) {
      final matchesStatus =
          _activeStatusFilter == null || match.status == _activeStatusFilter;
      final matchesSearch =
          query.isEmpty ||
          match.homeTeamName.toLowerCase().contains(query) ||
          match.awayTeamName.toLowerCase().contains(query) ||
          match.leagueName.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }
}

class FootballFeedBloc extends MatchFeedBloc {
  FootballFeedBloc(GetMatchesUseCase uc) : super(uc, 'FOOTBALL');
}

class VolleyballFeedBloc extends MatchFeedBloc {
  VolleyballFeedBloc(GetMatchesUseCase uc) : super(uc, 'VOLLEYBALL');
}
