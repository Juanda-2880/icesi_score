abstract class CreateAdminState {
  const CreateAdminState();
}

class CreateAdminInitialState extends CreateAdminState {
  const CreateAdminInitialState();
}

class CreateAdminLoadingState extends CreateAdminState {
  const CreateAdminLoadingState();
}

class CreateAdminSuccessState extends CreateAdminState {
  const CreateAdminSuccessState();
}

class CreateAdminFailureState extends CreateAdminState {
  final String errorMessage;
  const CreateAdminFailureState(this.errorMessage);
}
