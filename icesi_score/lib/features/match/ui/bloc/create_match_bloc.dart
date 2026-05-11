import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../match/domain/usecases/get_teams_usecase.dart';
import '../../../match/domain/usecases/get_leagues_usecase.dart';
import '../../../match/domain/usecases/create_match_usecase.dart';
import '../../../match/domain/usecases/update_match_usecase.dart';
import '../../../match/domain/usecases/delete_match_usecase.dart';
import '../../../match/domain/exceptions/match_exception.dart';
import 'create_match_event.dart';
import 'create_match_state.dart';

class CreateMatchBloc extends Bloc<CreateMatchEvent, CreateMatchState> {
  final GetTeamsUseCase _getTeams;
  final GetLeaguesUseCase _getLeagues;
  final CreateMatchUseCase _createMatch;
  final UpdateMatchUseCase _updateMatch;
  final DeleteMatchUseCase _deleteMatch;

  CreateMatchBloc(
    this._getTeams,
    this._getLeagues,
    this._createMatch,
    this._updateMatch,
    this._deleteMatch,
  ) : super(const CreateMatchFormLoadingState()) {
    on<CreateMatchStartedEvent>(_onStarted);
    on<CreateMatchEditStartedEvent>(_onEditStarted);
    on<CreateMatchSportSelectedEvent>(_onSportSelected);
    on<CreateMatchSubmittedEvent>(_onSubmitted);
    on<EditMatchSubmittedEvent>(_onEditSubmitted);
    on<DeleteMatchRequestedEvent>(_onDeleteRequested);
  }

  Future<void> _onStarted(
    CreateMatchStartedEvent event,
    Emitter<CreateMatchState> emit,
  ) async {
    emit(const CreateMatchFormLoadingState());
    try {
      final teams = await _getTeams();
      final leagues = await _getLeagues();
      emit(CreateMatchFormReadyState(
        CreateMatchFormData(allTeams: teams, leagues: leagues),
      ));
    } on MatchException catch (e) {
      emit(CreateMatchFailureState(e.message));
    } on Exception {
      emit(const CreateMatchFailureState(
        'No se pudieron cargar los datos del formulario. Intenta de nuevo.',
      ));
    }
  }

  Future<void> _onEditStarted(
    CreateMatchEditStartedEvent event,
    Emitter<CreateMatchState> emit,
  ) async {
    emit(const CreateMatchFormLoadingState());
    try {
      final teams = await _getTeams();
      final leagues = await _getLeagues();
      emit(CreateMatchFormReadyState(
        CreateMatchFormData(
          allTeams: teams,
          leagues: leagues,
          selectedSport: event.existingMatch.sport,
          editMatchId: event.existingMatch.id,
        ),
      ));
    } on MatchException catch (e) {
      emit(CreateMatchFailureState(e.message));
    } on Exception {
      emit(const CreateMatchFailureState(
        'No se pudieron cargar los datos del formulario. Intenta de nuevo.',
      ));
    }
  }

  void _onSportSelected(
    CreateMatchSportSelectedEvent event,
    Emitter<CreateMatchState> emit,
  ) {
    final current = state;
    if (current is CreateMatchFormReadyState) {
      emit(CreateMatchFormReadyState(current.formData.withSport(event.sport)));
    }
  }

  Future<void> _onSubmitted(
    CreateMatchSubmittedEvent event,
    Emitter<CreateMatchState> emit,
  ) async {
    final current = state;
    if (current is! CreateMatchFormReadyState) return;

    emit(CreateMatchSubmittingState(current.formData));
    try {
      await _createMatch(
        sport: current.formData.selectedSport,
        homeTeamId: event.homeTeamId,
        awayTeamId: event.awayTeamId,
        leagueId: event.leagueId,
        matchDate: event.matchDate,
        matchTime: event.matchTime,
        venue: event.venue,
        notes: event.notes,
      );
      emit(const CreateMatchSuccessState());
    } on MatchException catch (e) {
      emit(CreateMatchFailureState(e.message, current.formData));
    } on Exception {
      emit(CreateMatchFailureState(
        'Error al crear el partido. Intenta de nuevo.',
        current.formData,
      ));
    }
  }

  Future<void> _onEditSubmitted(
    EditMatchSubmittedEvent event,
    Emitter<CreateMatchState> emit,
  ) async {
    final current = state;
    if (current is! CreateMatchFormReadyState) return;
    final matchId = current.formData.editMatchId;
    if (matchId == null) return;

    emit(CreateMatchSubmittingState(current.formData));
    try {
      await _updateMatch(
        id: matchId,
        sport: current.formData.selectedSport,
        homeTeamId: event.homeTeamId,
        awayTeamId: event.awayTeamId,
        leagueId: event.leagueId,
        matchDate: event.matchDate,
        matchTime: event.matchTime,
        venue: event.venue,
        notes: event.notes,
      );
      emit(const CreateMatchSuccessState(isEdit: true));
    } on MatchException catch (e) {
      emit(CreateMatchFailureState(e.message, current.formData));
    } on Exception {
      emit(CreateMatchFailureState(
        'Error al editar el partido. Intenta de nuevo.',
        current.formData,
      ));
    }
  }

  Future<void> _onDeleteRequested(
    DeleteMatchRequestedEvent event,
    Emitter<CreateMatchState> emit,
  ) async {
    emit(const DeleteMatchInProgressState());
    try {
      await _deleteMatch(event.matchId);
      emit(const DeleteMatchSuccessState());
    } on MatchException catch (e) {
      emit(CreateMatchFailureState(e.message));
    } on Exception {
      emit(const CreateMatchFailureState('Error al eliminar el partido. Intenta de nuevo.'));
    }
  }
}
