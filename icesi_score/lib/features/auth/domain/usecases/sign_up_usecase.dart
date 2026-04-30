import '../repository/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  const SignUpUseCase(this._repository);

  Future<void> call({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String university,
  }) =>
      _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        university: university,
      );
}
