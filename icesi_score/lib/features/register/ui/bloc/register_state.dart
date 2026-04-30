abstract class RegisterState {
  const RegisterState();
}

class RegisterInitialState extends RegisterState {
  const RegisterInitialState();
}

class RegisterLoadingState extends RegisterState {
  const RegisterLoadingState();
}

class RegisterSuccessState extends RegisterState {
  const RegisterSuccessState();
}

class RegisterFailureState extends RegisterState {
  final String errorMessage;

  const RegisterFailureState(this.errorMessage);
}
