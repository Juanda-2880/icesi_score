import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class CognitoAuthDataSource {
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String university,
  }) async {
    try {
      await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            CognitoUserAttributeKey.email: email,
            CognitoUserAttributeKey.name: fullName,
            CognitoUserAttributeKey.phoneNumber: phone,
            const CognitoUserAttributeKey.custom('university'): university,
          },
        ),
      );
    } on UsernameExistsException {
      throw const AuthException('Ya existe una cuenta con ese correo electrónico.');
    } on InvalidPasswordException catch (e) {
      throw AuthException('Contraseña inválida: ${e.message}');
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      throw AuthException('Error al registrarse: $e');
    }
  }

  Future<void> confirmSignUp({
    required String email,
    required String code,
  }) async {
    try {
      await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: code,
      );
    } on CodeMismatchException {
      throw const AuthException('Código de verificación incorrecto.');
    } on ExpiredCodeException {
      throw const AuthException('El código ha expirado. Solicita uno nuevo.');
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      throw AuthException('Error al confirmar registro: $e');
    }
  }

  // Returns {userId, email} on success.
  Future<Map<String, String>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (!result.isSignedIn) {
        throw const AuthException('No se pudo completar el inicio de sesión.');
      }

      final attributes = await Amplify.Auth.fetchUserAttributes();
      final sub = attributes
          .firstWhere(
            (a) => a.userAttributeKey == CognitoUserAttributeKey.sub,
            orElse: () => throw const AuthException('No se encontró el identificador de usuario.'),
          )
          .value;

      return {'userId': sub, 'email': email};
    } on InvalidStateException {
      await Amplify.Auth.signOut();
      throw const AuthException('Sesión detectada. Por favor, inténtelo otra vez.');
    } on UserNotConfirmedException {
      throw const AuthException('La cuenta no ha sido verificada. Revisa tu correo.');
    } on UserNotFoundException {
      throw const AuthException('Acceso inválido. Por favor, inténtelo otra vez.');
    } on NotAuthorizedServiceException {
      throw const AuthException('Acceso inválido. Por favor, inténtelo otra vez.');
    } on AuthException {
      throw const AuthException('Acceso inválido. Por favor, inténtelo otra vez.');
    } on Exception catch (e) {
      throw AuthException('Error de conexión. Verifica tu red e inténtalo de nuevo.');
    }
  }

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } on Exception catch (e) {
      throw AuthException('Error al cerrar sesión: $e');
    }
  }
}
