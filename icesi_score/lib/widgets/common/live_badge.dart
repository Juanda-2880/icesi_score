import 'package:flutter/material.dart';

class LiveBadge extends StatelessWidget{
  
  const LiveBadge({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  
}