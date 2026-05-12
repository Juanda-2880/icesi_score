import 'package:flutter/material.dart';

const _kAvatarColors = [
  Color(0xFF4343D8),
  Color(0xFFFF8C42),
  Color(0xFF6C63FF),
  Color(0xFF2ECC71),
  Color(0xFFE74C3C),
  Color(0xFF3498DB),
];

Color teamColor(String teamId) =>
    _kAvatarColors[teamId.hashCode.abs() % _kAvatarColors.length];

String teamInitials(String name) =>
    name.substring(0, name.length.clamp(0, 2)).toUpperCase();
