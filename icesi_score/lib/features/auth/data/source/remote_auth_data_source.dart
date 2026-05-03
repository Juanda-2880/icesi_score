abstract class RemoteAuthDataSource {
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String university,
  });

  Future<void> confirmSignUp({required String email, required String code});

  Future<Map<String, String?>> signIn({
    required String email,
    required String password,
  });

  Future<void> confirmNewPassword(String newPassword);

  Future<void> signOut();

  Future<bool> isSessionValid();

  Future<String> getIdToken();

  Future<void> deleteUser();
}
