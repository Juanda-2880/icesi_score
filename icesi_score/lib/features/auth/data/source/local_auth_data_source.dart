import '../../domain/entities/auth_user.dart';

abstract class LocalAuthDataSource {
  Future<void> saveSession(AuthUser user);
  Future<AuthUser?> getSession();
  Future<void> clearSession();
}
