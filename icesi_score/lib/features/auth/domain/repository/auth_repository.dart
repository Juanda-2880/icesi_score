import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String university,
  });

  Future<void> confirmSignUp({
    required String email,
    required String code,
  });

  Future<void> signOut();
}
