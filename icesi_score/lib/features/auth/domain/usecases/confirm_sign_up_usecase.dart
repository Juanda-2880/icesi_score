import '../repository/auth_repository.dart';

class ConfirmSignUpUseCase {
  final AuthRepository _repository;

  const ConfirmSignUpUseCase(this._repository);

  Future<void> call({
    required String email,
    required String code,
  }) =>
      _repository.confirmSignUp(email: email, code: code);
}
