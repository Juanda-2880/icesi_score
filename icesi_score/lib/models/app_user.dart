enum UserRole { admin, fan }

class AppUser {
  final String token;
  final UserRole role;

  const AppUser ({required this.token, required this.role});
}