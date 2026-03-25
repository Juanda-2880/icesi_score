import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:url_launcher/url_launcher.dart'; // Librería para el In-App Browser
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _useSSO = false;

  // 1. Login tradicional con Cognito y enrutamiento por roles
  Future<void> _signInWithCognito() async {
    setState(() => _isLoading = true);
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result.isSignedIn && mounted) {
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        final jwtToken = session.userPoolTokensResult.value.accessToken.raw;

        Map<String, dynamic> decodedToken = JwtDecoder.decode(jwtToken);
        List<dynamic> groups = decodedToken['cognito:groups'] ?? [];

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
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.message}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. SSO de Icesi usando In-App Browser (Prototipo UX)
  // 2. SSO de Icesi usando In-App Browser (SIMULACIÓN PARA PRESENTACIÓN)
  Future<void> _signInWithSSO() async {
    final Uri ssoUrl = Uri.parse('https://portal.icesi.edu.co/');

    try {
      // 1. Abrimos el navegador in-app.
      // El código se pausa aquí hasta que el usuario cierre la ventana (la 'X').
      await launchUrl(ssoUrl, mode: LaunchMode.inAppBrowserView);

      // 2. Cuando el usuario cierra el navegador, SIMULAMOS que el login fue un éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulando validación OIDC exitosa...'),
            backgroundColor: Colors.green,
          ),
        );

        // 3. Enrutamos directamente a la vista de Administrador con un Token Falso
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AdminDashboardScreen(token: "mock_sso_admin_token_fase2"),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el portal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch para el SSO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Use Icesi SSO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: _useSSO,
                    activeColor: const Color(0xFF5C5CFF),
                    onChanged: (value) => setState(() => _useSSO = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Vista Condicional
            if (_useSSO) ...[
              const Center(
                child: Text(
                  'Log in using your university credentials.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _signInWithSSO, // Llama al WebView
                icon: const Icon(Icons.school, color: Colors.white),
                label: const Text('Continue with Icesi SSO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C5CFF),
                ),
              ),
            ] else ...[
              const Text(
                'Email',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'your.email@uicesi.edu.co',
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5C5CFF),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _signInWithCognito,
                      child: const Text('Log In'),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
