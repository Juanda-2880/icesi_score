import '../entities/auth_user.dart';
import '../repository/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  const SignInUseCase(this._repository);

  Future<AuthUser> call({
    required String email,
    required String password,
  }) =>
      _repository.signIn(email: email, password: password);
}
