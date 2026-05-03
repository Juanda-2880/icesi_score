import '../../domain/entities/auth_user.dart';

abstract class UserProfileDataSource {
  Future<AuthUser> fetchProfile(String idToken);

  Future<AuthUser> updateProfile({
    required String idToken,
    required String id,
    required String fullName,
    required String phone,
    required String university,
  });

  Future<void> deleteAccount({required String idToken});

  Future<void> createAdminUser({
    required String idToken,
    required String fullName,
    required String email,
    required String phone,
    required String university,
  });
}
