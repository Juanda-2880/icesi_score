import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/app_user.dart';

class AuthService {
  static const String superAdminEmail = 'admin@uicesi.edu.co';

  // Revisa si hay sesión activa al arrancar la app.
  // Retorna AppUser si hay sesión, null si no.
  static Future<AppUser?> checkExistingSession() async {
    final session = await Amplify.Auth.fetchAuthSession();
    if (!session.isSignedIn) return null;
    return await _buildUserFromSession();
  }

  // Login con email y contraseña.
  // Retorna AppUser si el login fue exitoso, lanza AuthException si falla.
  static Future<AppUser> signIn(String email, String password) async {
    final result = await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
    if (!result.isSignedIn) {
      throw Exception('Sign in did not complete.');
    }
    return await _buildUserFromSession();
  }

  // Registro de nuevo usuario.
  // Solo lanza excepción si falla; el navegador decide qué pantalla sigue.
  static Future<void> signUp(String email, String password, String name) async {
    await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(
        userAttributes: {
          AuthUserAttributeKey.email: email,
          AuthUserAttributeKey.name: name,
        },
      ),
    );
  }

  // Confirma el código de verificación y luego hace auto-login.
  // Retorna AppUser listo para navegar.
  static Future<AppUser> confirmAndSignIn(
    String email,
    String password,
    String code,
  ) async {
    // Intentar confirmar. Si ya estaba confirmado, se ignora el error.
    try {
      await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: code,
      );
    } on AuthException catch (e) {
      final alreadyConfirmed =
          e.message.contains('Current status is CONFIRMED') ||
          e.message.contains('User cannot be confirmed');
      if (!alreadyConfirmed) rethrow;
    }

    // Auto-login inmediato después de confirmar.
    return await signIn(email, password);
  }

  // Cierra la sesión activa.
  static Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  // Extrae el JWT de la sesión activa, decodifica el rol y construye AppUser.
  // Método privado: solo AuthService lo usa internamente.
  static Future<AppUser> _buildUserFromSession() async {
    final session =
        await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    final jwtToken = session.userPoolTokensResult.value.accessToken.raw;
    final decodedToken = JwtDecoder.decode(jwtToken);
    
    // In Cognito, email might be in 'email' or 'username' depending on config, 
    // but usually 'email' in claims.
    final String email = decodedToken['email'] ?? '';
    final List<dynamic> groups = decodedToken['cognito:groups'] ?? [];

    UserRole role;
    if (email == superAdminEmail) {
      role = UserRole.superAdmin;
    } else if (groups.contains('Admins')) {
      role = UserRole.admin;
    } else {
      role = UserRole.fan;
    }

    return AppUser(email: email, token: jwtToken, role: role);
  }
}
