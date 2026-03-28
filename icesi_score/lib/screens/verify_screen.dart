import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  final String password; // CAMBIO: Recibimos la contraseña de nuevo

  const VerifyScreen({super.key, required this.email, required this.password});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyAndLogin() async {
    setState(() => _isLoading = true);
    try {
      // 1. INTENTAR CONFIRMAR EL CÓDIGO
      try {
        await Amplify.Auth.confirmSignUp(
          username: widget.email,
          confirmationCode: _codeController.text.trim(),
        );
      } on AuthException catch (e) {
        if (e.message.contains('Current status is CONFIRMED') ||
            e.message.contains('User cannot be confirmed')) {
          print(
            'El usuario ya estaba verificado. Procediendo al auto-login...',
          );
        } else {
          rethrow;
        }
      }

      // 2. AUTO-LOGIN DIRECTO
      final signInResult = await Amplify.Auth.signIn(
        username: widget.email,
        password: widget.password,
      );

      if (signInResult.isSignedIn && mounted) {
        // Extraemos el Token y los roles
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        final jwtToken = session.userPoolTokensResult.value.accessToken.raw;

        Map<String, dynamic> decodedToken = JwtDecoder.decode(jwtToken);
        List<dynamic> groups = decodedToken['cognito:groups'] ?? [];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido! Sesión iniciada.'),
            backgroundColor: Colors.green,
          ),
        );

        // Redirigimos al Home o al Panel de Admin según corresponda
        if (groups.contains('Admins')) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboardScreen(token: jwtToken),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(token: jwtToken)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Identity')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We sent a 6-digit code to ${widget.email}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter 6-digit code'),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5C5CFF)),
                  )
                : ElevatedButton(
                    onPressed: _verifyAndLogin,
                    child: const Text(
                      'Verify and Enter App',
                    ), // Actualizamos el texto del botón
                  ),
          ],
        ),
      ),
    );
  }
}
