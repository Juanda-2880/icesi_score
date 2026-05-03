class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class NewPasswordRequiredException extends AuthException {
  const NewPasswordRequiredException()
      : super('Se requiere establecer una nueva contraseña.');
}
