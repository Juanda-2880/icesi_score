import '../../domain/entities/auth_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../source/cognito_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final CognitoAuthDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _dataSource.signIn(email: email, password: password);
    // role='NORMAL' provisional; el rol real se sincroniza con RDS tras el login
    return AuthUser(
      id: data['userId']!,
      email: data['email']!,
      fullName: '',
      role: 'NORMAL',
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String university,
  }) =>
      _dataSource.signUp(
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
      _dataSource.confirmSignUp(email: email, code: code);

  @override
  Future<void> signOut() => _dataSource.signOut();
}
