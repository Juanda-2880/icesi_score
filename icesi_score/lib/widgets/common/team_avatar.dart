import 'package:flutter/material.dart';

class TeamAvatar extends StatelessWidget {
  final String initials;
  final Color backgroundColor;
  final double radius;

  const TeamAvatar({
    super.key,
    required this.initials,
    required this.backgroundColor,
    this.radius = 20.0,
  }) : assert(initials.length <= 2, 'Las iniciales no deben superar 2 caracteres');

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}