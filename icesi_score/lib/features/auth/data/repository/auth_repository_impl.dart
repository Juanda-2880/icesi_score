import '../../domain/entities/auth_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../source/cognito_auth_data_source.dart';
import '../source/secure_storage_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final CognitoAuthDataSource _cognito;
  final SecureStorageDataSource _storage;

  AuthRepositoryImpl(this._cognito, [SecureStorageDataSource? storage])
      : _storage = storage ?? SecureStorageDataSource();

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _cognito.signIn(email: email, password: password);
    final user = AuthUser(
      id: data['userId']!,
      email: data['email']!,
      fullName: '',
      role: 'NORMAL',
    );
    await _storage.saveSession(user);
    return user;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String university,
  }) =>
      _cognito.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        university: university,
      );

  @override
  Future<void> confirmSignUp({
    required String email,
    required String code,
  }) =>
      _cognito.confirmSignUp(email: email, code: code);

  @override
  Future<void> signOut() async {
    await _cognito.signOut();
    await _storage.clearSession();
  }

  @override
  Future<AuthUser?> getStoredSession() => _storage.getSession();

  @override
  Future<void> clearSession() => _storage.clearSession();
}
