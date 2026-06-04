import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/entities/lineup_player.dart';

// ---------------------------------------------------------------------------
// VolleyballEventBottomSheet
// Matches PlayerEventBottomSheet style: drag handle, CircleAvatar header,
// colored left-border event tiles.
// ---------------------------------------------------------------------------

class VolleyballEventBottomSheet extends StatelessWidget {
  final LineupPlayer player;
  final bool isBenchPlayer;
  final bool wasSubstitutedOut;
  final bool isHome;
  final void Function(String eventType) onEventSelected;

  const VolleyballEventBottomSheet({
    super.key,
    required this.player,
    required this.isBenchPlayer,
    this.wasSubstitutedOut = false,
    required this.isHome,
    required this.onEventSelected,
  });

  static const _fieldEvents = [
    _VbEventOption(
        'POINT', 'Punto', Icons.sports_volleyball, Color(0xFF4CAF50)),
    _VbEventOption(
        'SERVICE_ACE', 'Ace de Servicio', Icons.flash_on, Color(0xFFFFEB3B)),
    _VbEventOption('BLOCK', 'Bloqueo', Icons.shield, Color(0xFF2196F3)),
    _VbEventOption('ROTATION_FAULT', 'Falta de Rotación', Icons.warning_amber,
        Color(0xFFF44336)),
    _VbEventOption(
        'SUBSTITUTION', 'Sustitución', Icons.swap_horiz, Color(0xFF9C27B0)),
    _VbEventOption(
        'NOTE', 'Agregar Nota', Icons.note_add, Color(0xFF607D8B)),
  ];

  // Original bench players: can be substituted in
  static const _benchEvents = [
    _VbEventOption(
        'SUBSTITUTION', 'Sustitución', Icons.swap_horiz, Color(0xFF9C27B0)),
    _VbEventOption(
        'NOTE', 'Agregar Nota', Icons.note_add, Color(0xFF607D8B)),
  ];

  // Players who already left the field cannot re-enter
  static const _substitutedOutEvents = [
    _VbEventOption(
        'NOTE', 'Agregar Nota', Icons.note_add, Color(0xFF607D8B)),
  ];

  @override
  Widget build(BuildContext context) {
    final teamColor = isHome ? AppTheme.teamColorA : AppTheme.teamColorB;
    final events = isBenchPlayer
        ? (wasSubstitutedOut ? _substitutedOutEvents : _benchEvents)
        : _fieldEvents;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Player header
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
            (opt) => _VbEventTile(
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

class _VbEventOption {
  final String type;
  final String label;
  final IconData icon;
  final Color color;
  const _VbEventOption(this.type, this.label, this.icon, this.color);
}

class _VbEventTile extends StatelessWidget {
  final _VbEventOption option;
  final VoidCallback onTap;

  const _VbEventTile({required this.option, required this.onTap});

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

// ---------------------------------------------------------------------------
// VolleyballScoringDialog — for POINT, SERVICE_ACE, BLOCK, ROTATION_FAULT
// ---------------------------------------------------------------------------

class VolleyballScoringDialog extends StatelessWidget {
  final String eventType;
  final LineupPlayer player;
  final void Function() onConfirm;

  const VolleyballScoringDialog({
    super.key,
    required this.eventType,
    required this.player,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String eventType,
    required LineupPlayer player,
    required void Function() onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) => VolleyballScoringDialog(
        eventType: eventType,
        player: player,
        onConfirm: onConfirm,
      ),
    );
  }

  static const _titles = {
    'POINT': 'Registrar Punto',
    'SERVICE_ACE': 'Registrar Ace de Servicio',
    'BLOCK': 'Registrar Bloqueo',
    'ROTATION_FAULT': 'Registrar Falta de Rotación',
  };

  static const _descriptions = {
    'POINT': 'El punto se sumará al equipo del jugador.',
    'SERVICE_ACE': 'El ace se sumará al equipo del jugador.',
    'BLOCK': 'El bloqueo se sumará al equipo del jugador.',
    'ROTATION_FAULT': 'La falta sumará un punto al equipo contrario.',
  };

  @override
  Widget build(BuildContext context) {
    final title = _titles[eventType] ?? 'Registrar Evento';
    final desc = _descriptions[eventType] ?? '';

    return AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${player.jerseyNumber} · ${player.playerName}',
            style: const TextStyle(
                color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: const BorderSide(color: Colors.white24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// VolleyballSubstitutionDialog
// ---------------------------------------------------------------------------

class VolleyballSubstitutionDialog extends StatefulWidget {
  final LineupPlayer initiator;
  final bool initiatorIsBench;
  final List<LineupPlayer> selectablePlayers;
  final void Function({
    required String playerOutId,
    required String playerInId,
  }) onConfirm;

  const VolleyballSubstitutionDialog({
    super.key,
    required this.initiator,
    required this.initiatorIsBench,
    required this.selectablePlayers,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required LineupPlayer initiator,
    required bool initiatorIsBench,
    required List<LineupPlayer> selectablePlayers,
    required void Function({
      required String playerOutId,
      required String playerInId,
    }) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) => VolleyballSubstitutionDialog(
        initiator: initiator,
        initiatorIsBench: initiatorIsBench,
        selectablePlayers: selectablePlayers,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<VolleyballSubstitutionDialog> createState() =>
      _VolleyballSubstitutionDialogState();
}

class _VolleyballSubstitutionDialogState
    extends State<VolleyballSubstitutionDialog> {
  LineupPlayer? _selected;

  @override
  Widget build(BuildContext context) {
    final dropdownLabel = widget.initiatorIsBench
        ? 'Jugador que sale (campo)'
        : 'Jugador que entra (banca)';

    return AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title:
          const Text('Sustitución', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initiatorIsBench ? 'Entra:' : 'Sale:',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            '${widget.initiator.jerseyNumber} · ${widget.initiator.playerName}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(dropdownLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          DropdownButtonFormField<LineupPlayer>(
            initialValue: _selected,
            dropdownColor: AppTheme.cardSurface,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF1E1E2E),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Seleccionar jugador',
                style: TextStyle(color: Colors.white38)),
            items: widget.selectablePlayers
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p.jerseyNumber} · ${p.playerName}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selected == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  final playerOut = widget.initiatorIsBench
                      ? _selected!
                      : widget.initiator;
                  final playerIn = widget.initiatorIsBench
                      ? widget.initiator
                      : _selected!;
                  widget.onConfirm(
                    playerOutId: playerOut.playerId,
                    playerInId: playerIn.playerId,
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// VolleyballNoteDialog
// ---------------------------------------------------------------------------

class VolleyballNoteDialog extends StatefulWidget {
  final LineupPlayer player;
  final void Function(String note) onConfirm;

  const VolleyballNoteDialog({
    super.key,
    required this.player,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required LineupPlayer player,
    required void Function(String note) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          VolleyballNoteDialog(player: player, onConfirm: onConfirm),
    );
  }

  @override
  State<VolleyballNoteDialog> createState() => _VolleyballNoteDialogState();
}

class _VolleyballNoteDialogState extends State<VolleyballNoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Agregar Nota',
          style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.player.jerseyNumber} · ${widget.player.playerName}',
            style: const TextStyle(
                color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLength: 200,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Escribe una nota...',
              hintStyle: TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Color(0xFF1E1E2E),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final note = _controller.text.trim();
            if (note.isEmpty) return;
            Navigator.of(context).pop();
            widget.onConfirm(note);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
