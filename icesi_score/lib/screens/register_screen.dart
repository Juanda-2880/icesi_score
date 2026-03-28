import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Amplify.Auth.signUp(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: _emailController.text.trim(),
            AuthUserAttributeKey.name: _nameController.text.trim(),
          },
        ),
      );

      if (mounted) {
        // CAMBIO: Volvemos a mandar la contraseña para poder hacer el auto-login
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyScreen(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... (El resto del método build queda exactamente igual) ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Full Name',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Your full name'),
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 20),

            const Text(
              'Confirm Password',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: '••••••••'),
            ),
            const SizedBox(height: 40),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5C5CFF)),
                  )
                : ElevatedButton(
                    onPressed: _signUp,
                    child: const Text('Create Account'),
                  ),
          ],
        ),
      ),
    );
  }
}
