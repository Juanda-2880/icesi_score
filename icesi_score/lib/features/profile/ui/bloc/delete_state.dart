abstract class DeleteState {
  const DeleteState();
}

class DeleteInitialState extends DeleteState {
  const DeleteInitialState();
}

class DeletingState extends DeleteState {
  const DeletingState();
}

class DeleteSuccessState extends DeleteState {
  const DeleteSuccessState();
}

class DeleteFailureState extends DeleteState {
  final String errorMessage;
  const DeleteFailureState(this.errorMessage);
}
