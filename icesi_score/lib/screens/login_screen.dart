import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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

  // Login tradicional con Cognito
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

  // Placeholder para el SSO de Icesi usando OIDC
  Future<void> _signInWithSSO() async {
    try {
      // Este es el llamado real que hará Flutter cuando configuremos el OIDC en AWS Cognito
      final result = await Amplify.Auth.signInWithWebUI(
        provider: const AuthProvider.custom('IcesiOIDC'),
      );

      if (result.isSignedIn && mounted) {
        // La lógica de extracción de Token y ruteo iría aquí también
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autenticación OIDC Exitosa'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Por ahora atrapamos el error hasta que configuremos la infraestructura
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Integración SSO (OIDC) planeada para la Fase 2 🚀'),
          backgroundColor: Color(0xFF5C5CFF),
        ),
      );
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
                onPressed: _signInWithSSO,
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
