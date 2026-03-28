import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'login_screen.dart'; // Importamos el Login para redirigir allá

class VerifyScreen extends StatefulWidget {
  final String email;

  // ¡Mira esto! Ya no exige "password"
  const VerifyScreen({super.key, required this.email});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyAndRedirectToLogin() async {
    setState(() => _isLoading = true);
    try {
      // 1. INTENTAR CONFIRMAR EL CÓDIGO
      try {
        await Amplify.Auth.confirmSignUp(
          username: widget.email,
          confirmationCode: _codeController.text.trim(),
        );
      } on AuthException catch (e) {
        // INTERCEPTOR: Si el error es porque ya estaba confirmado, seguimos adelante
        if (e.message.contains('Current status is CONFIRMED') ||
            e.message.contains('User cannot be confirmed')) {
          print('El usuario ya estaba verificado. Procediendo al Login...');
        } else {
          // Si es otro error (ej. pusiste mal el código de 6 dígitos), lanzamos el error a la pantalla
          rethrow;
        }
      }

      // 2. Éxito: Mostrar mensaje verde y redirigir al Login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Cuenta verificada con éxito! Inicia sesión para continuar.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // 3. Mandar al Login y borrar todo el historial de navegación para que no pueda devolverse
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
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
                    onPressed: _verifyAndRedirectToLogin,
                    child: const Text('Verify and Continue'),
                  ),
          ],
        ),
      ),
    );
  }
}
