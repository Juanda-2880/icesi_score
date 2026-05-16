import 'package:flutter/material.dart';
import '../../features/match/domain/entities/soccer_event.dart';
import '../../theme/app_theme.dart';

class SoccerEventCard extends StatelessWidget {
  final SoccerEvent event;
  final SoccerEvent? assist;
  final bool isDoubleYellow;
  final bool isExpanded;
  final VoidCallback onTap;

  const SoccerEventCard({
    super.key,
    required this.event,
    this.assist,
    this.isDoubleYellow = false,
    required this.isExpanded,
    required this.onTap,
  });

  String get _emoji {
    switch (event.eventType) {
      case 'GOAL':
        return '⚽';
      case 'YELLOW_CARD':
        return '🟡';
      case 'RED_CARD':
        return '🔴';
      case 'SUBSTITUTION':
        return '🔄';
      case 'NOTE':
        return '📝';
      default:
        return '•';
    }
  }

  String get _description {
    final team = event.teamName != null ? ' - ${event.teamName}' : '';
    switch (event.eventType) {
      case 'GOAL':
        final score =
            event.scoreAtMoment != null ? ' / Marcador: ${event.scoreAtMoment}' : '';
        return 'Gol$team$score';
      case 'YELLOW_CARD':
        return 'Tarjeta Amarilla$team';
      case 'RED_CARD':
        return 'Tarjeta Roja$team';
      case 'SUBSTITUTION':
        return 'Sustitución$team';
      case 'NOTE':
        return 'Nota$team';
      default:
        return event.eventType;
    }
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
                    width: 36,
                    child: Text(
                      "${event.minute}'",
                      style: const TextStyle(
                        color: AppTheme.appYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(_emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isDoubleYellow &&
                            event.eventType == 'YELLOW_CARD') ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '(Expulsado)',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                            ),
                          ),
                        ],
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
            if (isExpanded) ...[
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
                    ] else ...[
                      if (event.playerName != null)
                        _DetailRow(
                          label: 'Jugador',
                          value: event.playerName!,
                        ),
                      if (assist != null) ...[
                        const SizedBox(height: 8),
                        _AssistSubRow(assist: assist!),
                      ],
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
        Text(
          name,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _AssistSubRow extends StatelessWidget {
  final SoccerEvent assist;

  const _AssistSubRow({required this.assist});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('🅰️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            'Asistencia: ${assist.playerName ?? '-'}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
