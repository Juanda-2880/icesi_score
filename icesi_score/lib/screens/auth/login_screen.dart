import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart';
import '../../widgets/common/labeled_text_field.dart';
import '../../widgets/common/loading_button.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/super_admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) _navigateByRole(user);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateByRole(AppUser user) {
    Widget destination;
    if (user.role == UserRole.superAdmin) {
      destination = const SuperAdminScreen();
    } else if (user.role == UserRole.admin) {
      destination = AdminDashboardScreen(token: user.token);
    } else {
      destination = HomeScreen(token: user.token);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledTextField(
              label: 'Correo Electrónico',
              controller: _emailController,
              hint: 'tu.correo@uicesi.edu.co',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Contraseña',
              controller: _passwordController,
              hint: '••••••••',
              obscureText: true,
            ),
            const SizedBox(height: 40),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _handleLogin,
              label: 'Iniciar Sesión',
            ),
          ],
        ),
      ),
    );
  }
}
