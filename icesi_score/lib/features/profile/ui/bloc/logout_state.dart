abstract class LogoutState {
  const LogoutState();
}

class LogoutInitialState extends LogoutState {
  const LogoutInitialState();
}

class LogoutLoadingState extends LogoutState {
  const LogoutLoadingState();
}

class LogoutSuccessState extends LogoutState {
  const LogoutSuccessState();
}

class LogoutFailureState extends LogoutState {
  final String errorMessage;

  const LogoutFailureState(this.errorMessage);
}
