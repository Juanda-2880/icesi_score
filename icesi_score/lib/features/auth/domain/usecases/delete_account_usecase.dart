import '../repository/auth_repository.dart';

class DeleteAccountUseCase {
  final AuthRepository _repository;
  const DeleteAccountUseCase(this._repository);

  Future<void> call({required String id}) =>
      _repository.deleteAccount(id: id);
}
