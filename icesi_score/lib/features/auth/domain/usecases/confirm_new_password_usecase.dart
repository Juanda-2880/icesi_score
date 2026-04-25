import '../entities/auth_user.dart';
import '../repository/auth_repository.dart';

class ConfirmNewPasswordUseCase {
  final AuthRepository _repository;
  const ConfirmNewPasswordUseCase(this._repository);

  Future<AuthUser> call(String newPassword) =>
      _repository.confirmNewPassword(newPassword);
}
