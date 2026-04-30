import '../../domain/entities/auth_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../source/cognito_auth_data_source.dart';
import '../source/secure_storage_data_source.dart';
import '../source/user_profile_api_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final CognitoAuthDataSource _cognito;
  final SecureStorageDataSource _storage;
  final UserProfileApiDataSource _profileApi;

  AuthRepositoryImpl(
    this._cognito, [
    SecureStorageDataSource? storage,
    UserProfileApiDataSource? profileApi,
  ])  : _storage = storage ?? SecureStorageDataSource(),
        _profileApi = profileApi ?? UserProfileApiDataSource();

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _cognito.signIn(email: email, password: password);
      final idToken = await _cognito.getIdToken();
      final user = await _profileApi.fetchProfile(idToken);
      await _storage.saveSession(user);
      return user;
    } on AuthException {
      rethrow;
    } on Exception {
      try { await _cognito.signOut(); } catch (_) {}
      throw const AuthException('No se pudo obtener el perfil del usuario. Intenta de nuevo.');
    }
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
  Future<AuthUser?> getStoredSession() async {
    final valid = await _cognito.isSessionValid();
    if (!valid) {
      await _storage.clearSession();
      return null;
    }
    return _storage.getSession();
  }

  @override
  Future<void> clearSession() => _storage.clearSession();

  @override
  Future<void> deleteAccount({required String id}) async {
    // Step 1: delete DB record via Lambda (Lambda is in VPC — can reach RDS but not Cognito)
    try {
      final idToken = await _cognito.getIdToken();
      await _profileApi.deleteAccount(idToken: idToken);
    } on AuthException {
      rethrow;
    } on Exception {
      throw const AuthException('No se pudo eliminar la cuenta. Intenta de nuevo.');
    }
    // Step 2: delete Cognito user from client side (uses the user's own access token)
    // This also signs the user out automatically.
    await _cognito.deleteUser();
    await _storage.clearSession();
  }

  @override
  Future<AuthUser> confirmNewPassword(String newPassword) async {
    try {
      await _cognito.confirmNewPassword(newPassword);
      final idToken = await _cognito.getIdToken();
      final user = await _profileApi.fetchProfile(idToken);
      await _storage.saveSession(user);
      return user;
    } on AuthException {
      rethrow;
    } on Exception {
      throw const AuthException('No se pudo establecer la nueva contraseña. Intenta de nuevo.');
    }
  }

  @override
  Future<void> createAdminUser({
    required String fullName,
    required String email,
    required String phone,
    required String university,
  }) async {
    try {
      final idToken = await _cognito.getIdToken();
      await _profileApi.createAdminUser(
        idToken: idToken,
        fullName: fullName,
        email: email,
        phone: phone,
        university: university,
      );
    } on AuthException {
      rethrow;
    } on Exception {
      rethrow;
    }
  }

  @override
  Future<AuthUser> updateProfile({
    required String id,
    required String fullName,
    required String phone,
    required String university,
  }) async {
    try {
      final idToken = await _cognito.getIdToken();
      final user = await _profileApi.updateProfile(
        idToken: idToken,
        id: id,
        fullName: fullName,
        phone: phone,
        university: university,
      );
      await _storage.saveSession(user);
      return user;
    } on AuthException {
      rethrow;
    } on Exception {
      throw const AuthException('No se pudo actualizar el perfil. Intenta de nuevo.');
    }
  }
}
