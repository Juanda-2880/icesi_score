import '../entities/auth_user.dart';
import '../repository/auth_repository.dart';

class GetStoredSessionUseCase {
  final AuthRepository _repository;

  const GetStoredSessionUseCase(this._repository);

  Future<AuthUser?> call() => _repository.getStoredSession();
}
