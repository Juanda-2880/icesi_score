import 'package:flutter/material.dart';

class LiveModeScreen extends StatelessWidget {
  final String matchId;

  const LiveModeScreen({super.key, required this.matchId});

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
