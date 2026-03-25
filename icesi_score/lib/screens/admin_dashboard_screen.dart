import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String token;
  const AdminDashboardScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: const Center(
        child: Text(
          'Vista de Administrador',
          style: TextStyle(fontSize: 24, color: Colors.orangeAccent),
        ),
      ),
    );
  }
}
