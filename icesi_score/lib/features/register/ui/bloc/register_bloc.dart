import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/usecases/sign_up_usecase.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final SignUpUseCase _signUpUseCase;

  RegisterBloc(this._signUpUseCase) : super(const RegisterInitialState()) {
    on<RegisterSubmittedEvent>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    RegisterSubmittedEvent event,
    Emitter<RegisterState> emit,
  ) async {
    emit(const RegisterLoadingState());
    try {
      await _signUpUseCase(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        phone: event.phone,
        university: event.university,
      );
      emit(const RegisterSuccessState());
    } on Exception catch (e) {
      emit(RegisterFailureState(e.toString()));
    }
  }
}
