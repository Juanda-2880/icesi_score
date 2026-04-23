import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/usecases/sign_out_usecase.dart';
import 'logout_event.dart';
import 'logout_state.dart';

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final SignOutUseCase _signOutUseCase;

  LogoutBloc(this._signOutUseCase) : super(const LogoutInitialState()) {
    on<LogoutRequestedEvent>(_onRequested);
  }

  Future<void> _onRequested(
    LogoutRequestedEvent event,
    Emitter<LogoutState> emit,
  ) async {
    emit(const LogoutLoadingState());
    try {
      await _signOutUseCase();
      emit(const LogoutSuccessState());
    } on Exception catch (e) {
      emit(LogoutFailureState(e.toString()));
    }
  }
}
