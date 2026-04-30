import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppTopBar extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;

  const AppTopBar({
    super.key,
    required this.userName,
    required this.onProfileTap,
  });

  static const Color _purple = Color(0xFF4343D8);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: _purple,
            child: Icon(Icons.sports_soccer, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Search teams, matches...',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onProfileTap,
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: _purple,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
