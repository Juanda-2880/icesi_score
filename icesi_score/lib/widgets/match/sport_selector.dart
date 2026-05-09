import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SportSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SportSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SportTab(
          label: '⚽ Fútbol',
          isSelected: selectedIndex == 0,
          onTap: () => onSelected(0),
        ),
        _SportTab(
          label: '🏐 Voleibol',
          isSelected: selectedIndex == 1,
          onTap: () => onSelected(1),
        ),
      ],
    );
  }
}

class _SportTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SportTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white54,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
