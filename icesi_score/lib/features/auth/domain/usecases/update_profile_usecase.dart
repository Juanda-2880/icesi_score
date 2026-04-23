import '../entities/auth_user.dart';
import '../repository/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;
  const UpdateProfileUseCase(this._repository);

  Future<AuthUser> call({
    required String id,
    required String fullName,
    required String phone,
    required String university,
  }) =>
      _repository.updateProfile(
        id: id,
        fullName: fullName,
        phone: phone,
        university: university,
      );
}
