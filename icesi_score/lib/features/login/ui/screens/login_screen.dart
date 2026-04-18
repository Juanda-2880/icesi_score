import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../models/app_user.dart';
import '../../../../widgets/common/labeled_text_field.dart';
import '../../../../widgets/common/loading_button.dart';
import '../../../home/ui/screens/home_screen.dart';
import '../../../admin/ui/screens/admin_dashboard_screen.dart';

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
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateByRole(AppUser user) {
    final destination = user.role == UserRole.admin
        ? AdminDashboardScreen(token: user.token)
        : HomeScreen(token: user.token);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
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
            const SizedBox(height: 40),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _handleLogin,
              label: 'Log In',
            ),
          ],
        ),
      ),
    );
  }
}