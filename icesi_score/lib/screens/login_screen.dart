import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'home_screen.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _useSSO = false; // Controlador del Switch de SSO

  Future<void> _signInWithCognito() async {
    setState(() => _isLoading = true);
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result.isSignedIn && mounted) {
        // Obtener la sesión para sacar el Token
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        final jwtToken = session.userPoolTokensResult.value.accessToken.raw;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(token: jwtToken)),
          (route) => false,
        );
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

  void _signInWithSSO() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Integración con Icesi SSO planeada para la Fase 2 🚀'),
        backgroundColor: Color(0xFF5C5CFF),
      ),
    );
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
            // El Switch de SSO integrado en una tarjeta
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

            // Interfaz condicional: SSO vs Cognito Normal
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
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, // Aquí iría el "Olvidé mi contraseña"
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFF5C5CFF)),
                  ),
                ),
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
