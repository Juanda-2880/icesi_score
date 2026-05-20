import 'package:flutter/material.dart';
import '../../features/match/domain/entities/volleyball_event.dart';
import '../../theme/app_theme.dart';

class VolleyballEventCard extends StatelessWidget {
  final VolleyballEvent event;
  final bool isExpanded;
  final VoidCallback onTap;

  const VolleyballEventCard({
    super.key,
    required this.event,
    required this.isExpanded,
    required this.onTap,
  });

  String get _emoji {
    switch (event.eventType) {
      case 'POINT':
        return '🏐';
      case 'SERVICE_ACE':
        return '⚡';
      case 'BLOCK':
        return '🛡️';
      case 'ROTATION_FAULT':
        return '⚠️';
      case 'SUBSTITUTION':
        return '🔄';
      case 'NOTE':
        return '📝';
      default:
        return '•';
    }
  }

  String get _label {
    final team = event.teamName != null ? ' - ${event.teamName}' : '';
    switch (event.eventType) {
      case 'POINT':
        return 'Punto$team';
      case 'SERVICE_ACE':
        return 'Ace$team';
      case 'BLOCK':
        return 'Bloqueo$team';
      case 'ROTATION_FAULT':
        return 'Falta de rotación$team';
      case 'SUBSTITUTION':
        return 'Sustitución$team';
      case 'NOTE':
        return 'Nota$team';
      default:
        return event.eventType;
    }
  }

  bool get _hasExpandedContent {
    if (event.eventType == 'SUBSTITUTION') {
      return event.playerName != null || event.secondaryPlayerName != null;
    }
    if (event.eventType == 'NOTE') return event.note != null;
    return event.playerName != null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardInner,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      event.scoreMoment ?? '-',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(_emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Set ${event.setNumber}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (isExpanded && _hasExpandedContent) ...[
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(52, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.eventType == 'SUBSTITUTION') ...[
                      if (event.playerName != null)
                        _SubstitutionRow(
                          icon: Icons.arrow_downward,
                          color: Colors.red,
                          name: event.playerName!,
                        ),
                      if (event.secondaryPlayerName != null) ...[
                        const SizedBox(height: 4),
                        _SubstitutionRow(
                          icon: Icons.arrow_upward,
                          color: Colors.green,
                          name: event.secondaryPlayerName!,
                        ),
                      ],
                    ] else if (event.eventType == 'NOTE') ...[
                      if (event.note != null)
                        Text(
                          event.note!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ] else ...[
                      if (event.playerName != null)
                        Row(
                          children: [
                            const Text(
                              'Jugador: ',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                            Text(
                              event.playerName!,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubstitutionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;

  const _SubstitutionRow({
    required this.icon,
    required this.color,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
