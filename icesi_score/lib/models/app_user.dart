enum UserRole { superAdmin, admin, fan }

class AppUser {
  final String email;
  final String token;
  final UserRole role;

  const AppUser({required this.email, required this.token, required this.role});
}
