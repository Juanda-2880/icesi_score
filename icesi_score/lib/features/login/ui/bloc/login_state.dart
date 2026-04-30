import '../../../auth/domain/entities/auth_user.dart';

abstract class LoginState {
  const LoginState();
}

class LoginInitialState extends LoginState {
  const LoginInitialState();
}

class LoginLoadingState extends LoginState {
  const LoginLoadingState();
}

class LoginSuccessState extends LoginState {
  final AuthUser user;

  const LoginSuccessState(this.user);
}

class LoginFailureState extends LoginState {
  final String errorMessage;

  const LoginFailureState(this.errorMessage);
}

class LoginNewPasswordRequiredState extends LoginState {
  const LoginNewPasswordRequiredState();
}
