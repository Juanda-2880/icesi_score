class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? university;
  final String role;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.university,
    required this.role,
  });
}
