import 'package:flutter/material.dart';
import '../../features/match/domain/entities/lineup_player.dart';
import '../../theme/app_theme.dart';

class PlayerEventBottomSheet extends StatelessWidget {
  final LineupPlayer player;
  final bool isHome;
  final bool isBenchPlayer;
  final bool wasSubstitutedOut;
  final void Function(String eventType) onEventSelected;

  const PlayerEventBottomSheet({
    super.key,
    required this.player,
    required this.isHome,
    this.isBenchPlayer = false,
    this.wasSubstitutedOut = false,
    required this.onEventSelected,
  });

  static const _fieldEvents = [
    _EventOption('GOAL', 'Gol', Icons.sports_soccer, Color(0xFF4CAF50)),
    _EventOption('ASSIST', 'Asistencia', Icons.assistant, Color(0xFF2196F3)),
    _EventOption('YELLOW_CARD', 'Tarjeta Amarilla', Icons.square, Color(0xFFFFEB3B)),
    _EventOption('RED_CARD', 'Tarjeta Roja', Icons.square, Color(0xFFF44336)),
    _EventOption('SUBSTITUTION', 'Sustitución', Icons.swap_horiz, Color(0xFF9C27B0)),
    _EventOption('NOTE', 'Nota', Icons.note_add, Color(0xFF607D8B)),
  ];

  // Bench player who has never been on the field: can enter via SUBSTITUTION
  static const _benchEvents = [
    _EventOption('SUBSTITUTION', 'Sustitución', Icons.swap_horiz, Color(0xFF9C27B0)),
    _EventOption('YELLOW_CARD', 'Tarjeta Amarilla', Icons.square, Color(0xFFFFEB3B)),
    _EventOption('RED_CARD', 'Tarjeta Roja', Icons.square, Color(0xFFF44336)),
    _EventOption('NOTE', 'Nota', Icons.note_add, Color(0xFF607D8B)),
  ];

  // Substituted-out player: cannot re-enter the field
  static const _substitutedOutBenchEvents = [
    _EventOption('YELLOW_CARD', 'Tarjeta Amarilla', Icons.square, Color(0xFFFFEB3B)),
    _EventOption('RED_CARD', 'Tarjeta Roja', Icons.square, Color(0xFFF44336)),
    _EventOption('NOTE', 'Nota', Icons.note_add, Color(0xFF607D8B)),
  ];

  @override
  Widget build(BuildContext context) {
    final teamColor = isHome ? AppTheme.teamColorA : AppTheme.teamColorB;
    final events = isBenchPlayer
        ? (wasSubstitutedOut ? _substitutedOutBenchEvents : _benchEvents)
        : _fieldEvents;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: teamColor,
                  child: Text(
                    '${player.jerseyNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        player.teamName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBenchPlayer)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'BANCA',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 16, color: Colors.white12),
          ...events.map(
            (opt) => _EventTile(
              option: opt,
              onTap: () {
                Navigator.pop(context);
                onEventSelected(opt.type);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EventOption {
  final String type;
  final String label;
  final IconData icon;
  final Color color;
  const _EventOption(this.type, this.label, this.icon, this.color);
}

class _EventTile extends StatelessWidget {
  final _EventOption option;
  final VoidCallback onTap;

  const _EventTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: option.color, width: 4),
          ),
        ),
        child: ListTile(
          leading: Icon(option.icon, color: option.color),
          title: Text(
            option.label,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }
}
