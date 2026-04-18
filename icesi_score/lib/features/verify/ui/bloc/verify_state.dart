abstract class VerifyState {
  const VerifyState();
}

class VerifyInitialState extends VerifyState {
  const VerifyInitialState();
}

class VerifyLoadingState extends VerifyState {
  const VerifyLoadingState();
}

class VerifySuccessState extends VerifyState {
  const VerifySuccessState();
}

class VerifyFailureState extends VerifyState {
  final String errorMessage;

  const VerifyFailureState(this.errorMessage);
}
