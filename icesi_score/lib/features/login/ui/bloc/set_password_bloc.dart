import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/exceptions/auth_exception.dart';
import '../../../auth/domain/usecases/confirm_new_password_usecase.dart';
import 'set_password_event.dart';
import 'set_password_state.dart';

class SetPasswordBloc extends Bloc<SetPasswordEvent, SetPasswordState> {
  final ConfirmNewPasswordUseCase _confirmNewPasswordUseCase;

  SetPasswordBloc(this._confirmNewPasswordUseCase)
      : super(const SetPasswordInitialState()) {
    on<SetPasswordSubmittedEvent>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    SetPasswordSubmittedEvent event,
    Emitter<SetPasswordState> emit,
  ) async {
    emit(const SetPasswordLoadingState());
    try {
      final user = await _confirmNewPasswordUseCase(event.newPassword);
      emit(SetPasswordSuccessState(user));
    } on AuthException catch (e) {
      emit(SetPasswordFailureState(e.message));
    } on Exception {
      emit(const SetPasswordFailureState('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }
}
