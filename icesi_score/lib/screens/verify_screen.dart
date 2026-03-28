import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'welcome_screen.dart'; // CAMBIO: Ahora importamos el Welcome Screen

class VerifyScreen extends StatefulWidget {
  final String email;

  const VerifyScreen({super.key, required this.email});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  // Actualizamos el nombre de la función para mayor claridad
  Future<void> _verifyAndRedirectToWelcome() async {
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
            'El usuario ya estaba verificado. Procediendo a la pantalla de bienvenida...',
          );
        } else {
          rethrow;
        }
      }

      // 2. Éxito: Mostrar mensaje y redirigir a la pantalla principal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada y verificada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );

        // 3. CAMBIO: Mandar al WelcomeScreen y borrar el historial
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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
                    onPressed:
                        _verifyAndRedirectToWelcome, // CAMBIO: Llama a la nueva función
                    child: const Text('Verify and Continue'),
                  ),
          ],
        ),
      ),
    );
  }
}
