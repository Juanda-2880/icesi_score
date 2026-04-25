import '../../../auth/domain/entities/auth_user.dart';

abstract class SetPasswordState {
  const SetPasswordState();
}

class SetPasswordInitialState extends SetPasswordState {
  const SetPasswordInitialState();
}

class SetPasswordLoadingState extends SetPasswordState {
  const SetPasswordLoadingState();
}

class SetPasswordSuccessState extends SetPasswordState {
  final AuthUser user;
  const SetPasswordSuccessState(this.user);
}

class SetPasswordFailureState extends SetPasswordState {
  final String errorMessage;
  const SetPasswordFailureState(this.errorMessage);
}
