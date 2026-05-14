import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

Color teamColor(bool isHome) =>
    isHome ? AppTheme.teamColorA : AppTheme.teamColorB;

String teamInitials(String name) =>
    name.substring(0, name.length.clamp(0, 2)).toUpperCase();
