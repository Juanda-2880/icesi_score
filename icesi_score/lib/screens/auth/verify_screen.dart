import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart';
import '../../widgets/common/loading_button.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  final String password;

  const VerifyScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.confirmAndSignIn(
        widget.email,
        widget.password,
        _codeController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bienvenido! Sesion iniciada.'),
            backgroundColor: Colors.green,
          ),
        );
        _navigateByRole(user);
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
              decoration:
                  const InputDecoration(hintText: 'Enter 6-digit code'),
            ),
            const SizedBox(height: 40),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _handleVerify,
              label: 'Verify and Enter App',
            ),
          ],
        ),
      ),
    );
  }
}