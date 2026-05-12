import 'package:flutter/material.dart';
import '../../domain/entities/match.dart';

class LiveModeScreen extends StatelessWidget {
  final Match match;

  const LiveModeScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Live')),
      body: const Center(
        child: Text(
          'Próximamente...',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
