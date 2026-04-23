import '../../../auth/domain/entities/auth_user.dart';

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitialState extends ProfileState {
  const ProfileInitialState();
}

class ProfileSavingState extends ProfileState {
  const ProfileSavingState();
}

class ProfileSavedState extends ProfileState {
  final AuthUser user;
  const ProfileSavedState(this.user);
}

class ProfileSaveFailureState extends ProfileState {
  final String errorMessage;
  const ProfileSaveFailureState(this.errorMessage);
}
