import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/usecases/confirm_sign_up_usecase.dart';
import 'verify_event.dart';
import 'verify_state.dart';

class VerifyBloc extends Bloc<VerifyEvent, VerifyState> {
  final ConfirmSignUpUseCase _confirmSignUpUseCase;

  VerifyBloc(this._confirmSignUpUseCase) : super(const VerifyInitialState()) {
    on<VerifyCodeSubmittedEvent>(_onCodeSubmitted);
  }

  Future<void> _onCodeSubmitted(
    VerifyCodeSubmittedEvent event,
    Emitter<VerifyState> emit,
  ) async {
    emit(const VerifyLoadingState());
    try {
      await _confirmSignUpUseCase(email: event.email, code: event.code);
      emit(const VerifySuccessState());
    } on Exception catch (e) {
      emit(VerifyFailureState(e.toString()));
    }
  }
}
