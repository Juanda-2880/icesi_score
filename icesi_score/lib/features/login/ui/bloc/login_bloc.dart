import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/source/cognito_auth_data_source.dart';
import '../../../auth/domain/usecases/sign_in_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SignInUseCase _signInUseCase;

  LoginBloc(this._signInUseCase) : super(const LoginInitialState()) {
    on<LoginSubmittedEvent>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    LoginSubmittedEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoadingState());
    try {
      final user = await _signInUseCase(
        email: event.email,
        password: event.password,
      );
      emit(LoginSuccessState(user));
    } on AuthException catch (e) {
      emit(LoginFailureState(e.message));
    } on Exception {
      emit(const LoginFailureState('Ocurrió un error inesperado. Intenta de nuevo'));
    }
  }
}
