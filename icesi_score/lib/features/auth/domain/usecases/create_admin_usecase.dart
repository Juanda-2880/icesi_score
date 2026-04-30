import '../repository/auth_repository.dart';

class CreateAdminUseCase {
  final AuthRepository _repository;
  const CreateAdminUseCase(this._repository);

  Future<void> call({
    required String fullName,
    required String email,
    required String phone,
    required String university,
  }) =>
      _repository.createAdminUser(
        fullName: fullName,
        email: email,
        phone: phone,
        university: university,
      );
}
