import 'package:flutter/material.dart';

class MatchDetailScreen extends StatelessWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del partido')),
      body: const Center(
        child: Text(
          'Próximamente...',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
