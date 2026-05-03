import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' hide AuthException;
import 'package:amplify_flutter/amplify_flutter.dart' hide AuthException;
import '../../domain/exceptions/auth_exception.dart';
import 'remote_auth_data_source.dart';

class CognitoAuthDataSource implements RemoteAuthDataSource {
  @override
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

  @override
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

  // Returns {userId, email, fullName, phone, university} on success.
  @override
  Future<Map<String, String?>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (!result.isSignedIn) {
        if (result.nextStep.signInStep ==
            AuthSignInStep.confirmSignInWithNewPassword) {
          throw const NewPasswordRequiredException();
        }
        throw const AuthException('No se pudo completar el inicio de sesión.');
      }

      final attributes = await Amplify.Auth.fetchUserAttributes();

      String? findAttr(AuthUserAttributeKey key) {
        final matches = attributes.where((a) => a.userAttributeKey == key);
        return matches.isEmpty ? null : matches.first.value;
      }

      final sub = findAttr(CognitoUserAttributeKey.sub);
      if (sub == null || sub.isEmpty) {
        throw const AuthException('No se encontró el identificador de usuario.');
      }

      return {
        'userId': sub,
        'email': email,
        'fullName': findAttr(CognitoUserAttributeKey.name),
        'phone': findAttr(CognitoUserAttributeKey.phoneNumber),
        'university': findAttr(const CognitoUserAttributeKey.custom('university')),
      };
    } on InvalidStateException {
      await Amplify.Auth.signOut();
      throw const AuthException('Sesión detectada. Por favor, inténtelo otra vez.');
    } on UserNotConfirmedException {
      throw const AuthException('La cuenta no ha sido verificada. Revisa tu correo.');
    } on UserNotFoundException {
      throw const AuthException('Acceso inválido. Por favor, inténtelo otra vez.');
    } on NotAuthorizedServiceException {
      throw const AuthException('Acceso inválido. Por favor, inténtelo otra vez.');
    } on NewPasswordRequiredException {
      rethrow;
    } on AuthException {
      throw const AuthException('Acceso inválido. Por favor, inténtelo otra vez.');
    } on Exception {
      throw AuthException('Error de conexión. Verifica tu red e inténtalo de nuevo.');
    }
  }

  @override
  Future<void> confirmNewPassword(String newPassword) async {
    try {
      final result = await Amplify.Auth.confirmSignIn(confirmationValue: newPassword);
      if (!result.isSignedIn) {
        throw const AuthException('No se pudo establecer la nueva contraseña.');
      }
    } on AuthNotAuthorizedException {
      throw const AuthException('La contraseña temporal no es válida.');
    } on InvalidPasswordException catch (e) {
      throw AuthException('Contraseña inválida: ${e.message}');
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      throw AuthException('Error al cambiar contraseña: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut(
        options: const SignOutOptions(globalSignOut: true),
      );
    } on Exception catch (e) {
      throw AuthException('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<bool> isSessionValid() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> getIdToken() async {
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    return session.userPoolTokensResult.value.idToken.raw;
  }

  // Deletes the current Cognito user and signs them out automatically.
  @override
  Future<void> deleteUser() async {
    try {
      await Amplify.Auth.deleteUser();
    } on AuthException catch (e) {
      throw AuthException('Error al eliminar la cuenta de Cognito: ${e.message}');
    } on Exception catch (e) {
      throw AuthException('Error al eliminar la cuenta: $e');
    }
  }
}
