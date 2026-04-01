import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/labeled_text_field.dart';
import '../../widgets/common/loading_button.dart';
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

  Future<void> _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contrasenas no coinciden.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
      if (mounted) {
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
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledTextField(
              label: 'Full Name',
              controller: _nameController,
              hint: 'Your full name',
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Email',
              controller: _emailController,
              hint: 'your.email@uicesi.edu.co',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Password',
              controller: _passwordController,
              hint: '••••••••',
              obscureText: true,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Confirm Password',
              controller: _confirmPasswordController,
              hint: '••••••••',
              obscureText: true,
            ),
            const SizedBox(height: 40),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _handleRegister,
              label: 'Create Account',
            ),
          ],
        ),
      ),
    );
  }
}