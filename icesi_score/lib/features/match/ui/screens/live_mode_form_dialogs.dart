import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/entities/soccer_event.dart';
import '../../../../theme/app_theme.dart';

int _calcMinute(MatchPeriod? period) {
  if (period == null) return 0;
  final elapsed = DateTime.now().difference(period.startTime);
  return elapsed.inMinutes.clamp(0, 999);
}

// ── Goal ──────────────────────────────────────────────────────────────────────

class GoalEventDialog extends StatefulWidget {
  final LineupPlayer scorer;
  final List<LineupPlayer> teamOnField;
  final MatchPeriod? activePeriod;
  final void Function({
    required int minute,
    String? assistPlayerId,
  }) onConfirm;

  const GoalEventDialog({
    super.key,
    required this.scorer,
    required this.teamOnField,
    required this.activePeriod,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required LineupPlayer scorer,
    required List<LineupPlayer> teamOnField,
    required MatchPeriod? activePeriod,
    required void Function({required int minute, String? assistPlayerId})
        onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GoalEventDialog(
        scorer: scorer,
        teamOnField: teamOnField,
        activePeriod: activePeriod,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<GoalEventDialog> createState() => _GoalEventDialogState();
}

class _GoalEventDialogState extends State<GoalEventDialog> {
  late final TextEditingController _minuteCtrl;
  bool _withAssist = false;
  String? _assistPlayerId;

  @override
  void initState() {
    super.initState();
    _minuteCtrl =
        TextEditingController(text: '${_calcMinute(widget.activePeriod)}');
  }

  @override
  void dispose() {
    _minuteCtrl.dispose();
    super.dispose();
  }

  List<LineupPlayer> get _assistCandidates => widget.teamOnField
      .where((p) =>
          p.playerId != widget.scorer.playerId &&
          (p.status == 'STARTER' || p.status == 'ON_FIELD'))
      .toList();

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, insets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormHeader(
            label: 'GOL',
            color: const Color(0xFF4CAF50),
            player: widget.scorer,
          ),
          const SizedBox(height: 16),
          _MinuteField(controller: _minuteCtrl),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('¿Hubo asistencia?',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              const Spacer(),
              Switch(
                value: _withAssist,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() {
                  _withAssist = v;
                  if (!v) _assistPlayerId = null;
                }),
              ),
            ],
          ),
          if (_withAssist) ...[
            const SizedBox(height: 8),
            _PlayerDropdown(
              hint: 'Jugador que asistió',
              players: _assistCandidates,
              value: _assistPlayerId,
              onChanged: (v) => setState(() => _assistPlayerId = v),
            ),
          ],
          const SizedBox(height: 20),
          _ConfirmButton(
            enabled: !_withAssist || _assistPlayerId != null,
            onTap: () {
              final min = int.tryParse(_minuteCtrl.text) ?? 0;
              Navigator.pop(context);
              widget.onConfirm(
                minute: min,
                assistPlayerId: _withAssist ? _assistPlayerId : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Standalone Assist ─────────────────────────────────────────────────────────

class AssistEventDialog extends StatefulWidget {
  final LineupPlayer assister;
  final List<SoccerEvent> unassistedGoals;
  final MatchPeriod? activePeriod;
  final void Function({
    required int minute,
    required String parentEventId,
  }) onConfirm;

  const AssistEventDialog({
    super.key,
    required this.assister,
    required this.unassistedGoals,
    required this.activePeriod,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required LineupPlayer assister,
    required List<SoccerEvent> unassistedGoals,
    required MatchPeriod? activePeriod,
    required void Function({required int minute, required String parentEventId})
        onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AssistEventDialog(
        assister: assister,
        unassistedGoals: unassistedGoals,
        activePeriod: activePeriod,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AssistEventDialog> createState() => _AssistEventDialogState();
}

class _AssistEventDialogState extends State<AssistEventDialog> {
  late final TextEditingController _minuteCtrl;
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
    _minuteCtrl =
        TextEditingController(text: '${_calcMinute(widget.activePeriod)}');
  }

  @override
  void dispose() {
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, insets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormHeader(
            label: 'ASISTENCIA',
            color: const Color(0xFF2196F3),
            player: widget.assister,
          ),
          const SizedBox(height: 16),
          _MinuteField(controller: _minuteCtrl),
          const SizedBox(height: 16),
          const Text('Gol asistido',
              style:
                  TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          if (widget.unassistedGoals.isEmpty)
            const Text(
              'No hay goles sin asistencia en este partido.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            _StyledDropdown<String>(
              hint: 'Selecciona el gol',
              value: _selectedGoalId,
              items: widget.unassistedGoals
                  .map((g) => DropdownMenuItem(
                        value: g.id,
                        child: Text(
                          'Min ${g.minute} — ${g.playerName ?? "Desconocido"}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGoalId = v),
            ),
          const SizedBox(height: 20),
          _ConfirmButton(
            enabled: _selectedGoalId != null &&
                widget.unassistedGoals.isNotEmpty,
            onTap: () {
              final min = int.tryParse(_minuteCtrl.text) ?? 0;
              Navigator.pop(context);
              widget.onConfirm(
                minute: min,
                parentEventId: _selectedGoalId!,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Card (Yellow / Red) ───────────────────────────────────────────────────────

class CardEventDialog extends StatefulWidget {
  final String eventType;
  final LineupPlayer player;
  final MatchPeriod? activePeriod;
  final void Function({required int minute}) onConfirm;

  const CardEventDialog({
    super.key,
    required this.eventType,
    required this.player,
    required this.activePeriod,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String eventType,
    required LineupPlayer player,
    required MatchPeriod? activePeriod,
    required void Function({required int minute}) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CardEventDialog(
        eventType: eventType,
        player: player,
        activePeriod: activePeriod,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<CardEventDialog> createState() => _CardEventDialogState();
}

class _CardEventDialogState extends State<CardEventDialog> {
  late final TextEditingController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    _minuteCtrl =
        TextEditingController(text: '${_calcMinute(widget.activePeriod)}');
  }

  @override
  void dispose() {
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRed = widget.eventType == 'RED_CARD';
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, insets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormHeader(
            label: isRed ? 'TARJETA ROJA' : 'TARJETA AMARILLA',
            color: isRed ? const Color(0xFFF44336) : const Color(0xFFFFEB3B),
            player: widget.player,
          ),
          const SizedBox(height: 16),
          _MinuteField(controller: _minuteCtrl),
          if (isRed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFF44336).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: Color(0xFFF44336), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El jugador será expulsado del partido.',
                      style:
                          TextStyle(color: Color(0xFFF44336), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _ConfirmButton(
            onTap: () {
              final min = int.tryParse(_minuteCtrl.text) ?? 0;
              Navigator.pop(context);
              widget.onConfirm(minute: min);
            },
          ),
        ],
      ),
    );
  }
}

// ── Substitution ──────────────────────────────────────────────────────────────

class SubstitutionEventDialog extends StatefulWidget {
  final LineupPlayer playerOut;
  final List<LineupPlayer> benchPlayers;
  final MatchPeriod? activePeriod;
  final void Function({
    required int minute,
    required String playerInId,
  }) onConfirm;

  const SubstitutionEventDialog({
    super.key,
    required this.playerOut,
    required this.benchPlayers,
    required this.activePeriod,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required LineupPlayer playerOut,
    required List<LineupPlayer> benchPlayers,
    required MatchPeriod? activePeriod,
    required void Function({required int minute, required String playerInId})
        onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubstitutionEventDialog(
        playerOut: playerOut,
        benchPlayers: benchPlayers,
        activePeriod: activePeriod,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<SubstitutionEventDialog> createState() =>
      _SubstitutionEventDialogState();
}

class _SubstitutionEventDialogState extends State<SubstitutionEventDialog> {
  late final TextEditingController _minuteCtrl;
  String? _playerInId;

  @override
  void initState() {
    super.initState();
    _minuteCtrl =
        TextEditingController(text: '${_calcMinute(widget.activePeriod)}');
  }

  @override
  void dispose() {
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, insets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormHeader(
            label: 'SUSTITUCIÓN',
            color: const Color(0xFF9C27B0),
            player: widget.playerOut,
          ),
          const SizedBox(height: 4),
          const Text('Jugador que SALE del campo',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 16),
          _MinuteField(controller: _minuteCtrl),
          const SizedBox(height: 16),
          const Text('Jugador que ENTRA',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          if (widget.benchPlayers.isEmpty)
            const Text(
              'No hay suplentes disponibles.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            _PlayerDropdown(
              hint: 'Selecciona el suplente',
              players: widget.benchPlayers,
              value: _playerInId,
              onChanged: (v) => setState(() => _playerInId = v),
            ),
          const SizedBox(height: 20),
          _ConfirmButton(
            enabled: _playerInId != null && widget.benchPlayers.isNotEmpty,
            onTap: () {
              final min = int.tryParse(_minuteCtrl.text) ?? 0;
              Navigator.pop(context);
              widget.onConfirm(minute: min, playerInId: _playerInId!);
            },
          ),
        ],
      ),
    );
  }
}

// ── Note ──────────────────────────────────────────────────────────────────────

class NoteEventDialog extends StatefulWidget {
  final LineupPlayer player;
  final MatchPeriod? activePeriod;
  final void Function({required int minute, required String note}) onConfirm;

  const NoteEventDialog({
    super.key,
    required this.player,
    required this.activePeriod,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required LineupPlayer player,
    required MatchPeriod? activePeriod,
    required void Function({required int minute, required String note})
        onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NoteEventDialog(
        player: player,
        activePeriod: activePeriod,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<NoteEventDialog> createState() => _NoteEventDialogState();
}

class _NoteEventDialogState extends State<NoteEventDialog> {
  late final TextEditingController _minuteCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _minuteCtrl =
        TextEditingController(text: '${_calcMinute(widget.activePeriod)}');
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _minuteCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, insets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormHeader(
            label: 'NOTA',
            color: const Color(0xFF607D8B),
            player: widget.player,
          ),
          const SizedBox(height: 16),
          _MinuteField(controller: _minuteCtrl),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            maxLength: 200,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Escribe una nota...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: AppTheme.cardInner,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(color: Colors.grey),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _ConfirmButton(
            enabled: _noteCtrl.text.isNotEmpty,
            onTap: () {
              final min = int.tryParse(_minuteCtrl.text) ?? 0;
              Navigator.pop(context);
              widget.onConfirm(minute: min, note: _noteCtrl.text.trim());
            },
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _FormHeader extends StatelessWidget {
  final String label;
  final Color color;
  final LineupPlayer player;

  const _FormHeader({
    required this.label,
    required this.color,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            player.playerName,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '#${player.jerseyNumber}',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}

class _MinuteField extends StatelessWidget {
  final TextEditingController controller;

  const _MinuteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Minuto', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.cardInner,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerDropdown extends StatelessWidget {
  final String hint;
  final List<LineupPlayer> players;
  final String? value;
  final void Function(String?) onChanged;

  const _PlayerDropdown({
    required this.hint,
    required this.players,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StyledDropdown<String>(
      hint: hint,
      value: value,
      items: players
          .map((p) => DropdownMenuItem(
                value: p.playerId,
                child: Text(
                  '#${p.jerseyNumber} ${p.playerName}',
                  style: const TextStyle(color: Colors.white),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _StyledDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardInner,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppTheme.cardSurface,
        hint: Text(hint, style: const TextStyle(color: Colors.grey)),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ConfirmButton({this.enabled = true, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Confirmar',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
