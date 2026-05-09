import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/labeled_text_field.dart';
import '../../domain/entities/team.dart';
import '../bloc/create_match_bloc.dart';
import '../bloc/create_match_event.dart';
import '../bloc/create_match_state.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _venueController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedHomeTeamId;
  String? _selectedAwayTeamId;
  String? _selectedLeagueId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CreateMatchBloc>().add(const CreateMatchStartedEvent());
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSportSelected(String newSport, BuildContext ctx) {
    final current = ctx.read<CreateMatchBloc>().state;
    final currentSport = current is CreateMatchFormReadyState
        ? current.formData.selectedSport
        : 'FOOTBALL';

    if (newSport == currentSport) return;

    setState(() {
      _selectedHomeTeamId = null;
      _selectedAwayTeamId = null;
    });
    ctx.read<CreateMatchBloc>().add(CreateMatchSportSelectedEvent(newSport));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateController.text =
            '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<CreateMatchBloc>().add(CreateMatchSubmittedEvent(
      homeTeamId: _selectedHomeTeamId!,
      awayTeamId: _selectedAwayTeamId!,
      leagueId: _selectedLeagueId!,
      matchDate: _dateController.text.trim(),
      matchTime: _timeController.text.trim(),
      venue: _venueController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    ));
  }

  void _showError(BuildContext ctx, String message) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateMatchBloc, CreateMatchState>(
      listener: (ctx, state) {
        if (state is CreateMatchSuccessState) {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Partido creado exitosamente ✓')),
          );
        } else if (state is CreateMatchFailureState) {
          _showError(ctx, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Nuevo Partido'),
        ),
        body: BlocBuilder<CreateMatchBloc, CreateMatchState>(
          builder: (ctx, state) {
            if (state is CreateMatchFormLoadingState) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              );
            }

            CreateMatchFormData? formData;
            bool isSubmitting = false;

            if (state is CreateMatchFormReadyState) {
              formData = state.formData;
            } else if (state is CreateMatchSubmittingState) {
              formData = state.formData;
              isSubmitting = true;
            } else if (state is CreateMatchFailureState) {
              formData = state.formData;
            }

            if (formData == null) {
              return _RetryView(
                onRetry: () => ctx
                    .read<CreateMatchBloc>()
                    .add(const CreateMatchStartedEvent()),
              );
            }

            return _MatchForm(
              formKey: _formKey,
              formData: formData,
              isSubmitting: isSubmitting,
              dateController: _dateController,
              timeController: _timeController,
              venueController: _venueController,
              notesController: _notesController,
              selectedHomeTeamId: _selectedHomeTeamId,
              selectedAwayTeamId: _selectedAwayTeamId,
              selectedLeagueId: _selectedLeagueId,
              onSportSelected: (sport) => _onSportSelected(sport, ctx),
              onHomeTeamChanged: (v) => setState(() {
                if (_selectedAwayTeamId == v) _selectedAwayTeamId = null;
                _selectedHomeTeamId = v;
              }),
              onAwayTeamChanged: (v) => setState(() => _selectedAwayTeamId = v),
              onLeagueChanged: (v) => setState(() => _selectedLeagueId = v),
              onPickDate: _pickDate,
              onPickTime: _pickTime,
              onSubmit: () => _submit(ctx),
              onCancel: () => Navigator.of(ctx).pop(),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private form widget — StatelessWidget per architecture rules
// ---------------------------------------------------------------------------

class _MatchForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final CreateMatchFormData formData;
  final bool isSubmitting;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final TextEditingController venueController;
  final TextEditingController notesController;
  final String? selectedHomeTeamId;
  final String? selectedAwayTeamId;
  final String? selectedLeagueId;
  final void Function(String) onSportSelected;
  final void Function(String?) onHomeTeamChanged;
  final void Function(String?) onAwayTeamChanged;
  final void Function(String?) onLeagueChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _MatchForm({
    required this.formKey,
    required this.formData,
    required this.isSubmitting,
    required this.dateController,
    required this.timeController,
    required this.venueController,
    required this.notesController,
    required this.selectedHomeTeamId,
    required this.selectedAwayTeamId,
    required this.selectedLeagueId,
    required this.onSportSelected,
    required this.onHomeTeamChanged,
    required this.onAwayTeamChanged,
    required this.onLeagueChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final filteredTeams = formData.filteredTeams;
    final selectedSport = formData.selectedSport;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sport ──────────────────────────────────────────────────────
            _SectionLabel('Deporte'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SportCard(
                    emoji: '⚽',
                    label: 'Fútbol',
                    isSelected: selectedSport == 'FOOTBALL',
                    onTap: () => onSportSelected('FOOTBALL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SportCard(
                    emoji: '🏐',
                    label: 'Voleibol',
                    isSelected: selectedSport == 'VOLLEYBALL',
                    onTap: () => onSportSelected('VOLLEYBALL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Teams ──────────────────────────────────────────────────────
            _SectionLabel('Equipos'),
            const SizedBox(height: 10),
            _TeamDropdown(
              hint: '🏠 Equipo local',
              value: selectedHomeTeamId,
              teams: filteredTeams,
              excludeId: null,
              onChanged: onHomeTeamChanged,
              validator: (v) =>
                  v == null ? 'Selecciona el equipo local.' : null,
            ),
            const SizedBox(height: 14),
            _TeamDropdown(
              hint: '✈️ Equipo visitante',
              value: selectedAwayTeamId,
              teams: filteredTeams,
              excludeId: selectedHomeTeamId,
              onChanged: onAwayTeamChanged,
              validator: (v) {
                if (v == null) return 'Selecciona el equipo visitante.';
                if (v == selectedHomeTeamId) {
                  return 'Los equipos no pueden ser iguales.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Date ───────────────────────────────────────────────────────
            _SectionLabel('Fecha del Partido'),
            const SizedBox(height: 10),
            TextFormField(
              controller: dateController,
              readOnly: true,
              onTap: onPickDate,
              decoration: const InputDecoration(
                hintText: '📅 AAAA-MM-DD',
                suffixIcon:
                    Icon(Icons.calendar_today_outlined, size: 18),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Selecciona la fecha del partido.'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Time ───────────────────────────────────────────────────────
            _SectionLabel('Hora del Partido'),
            const SizedBox(height: 10),
            TextFormField(
              controller: timeController,
              readOnly: true,
              onTap: onPickTime,
              decoration: const InputDecoration(
                hintText: '🕐 HH:MM',
                suffixIcon: Icon(Icons.access_time_outlined, size: 18),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Selecciona la hora del partido.'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── League ─────────────────────────────────────────────────────
            _SectionLabel('Liga / Torneo'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedLeagueId),
              initialValue: selectedLeagueId,
              decoration:
                  const InputDecoration(hintText: '🏆 Seleccionar liga'),
              items: formData.leagues
                  .map((l) => DropdownMenuItem(
                        value: l.id,
                        child: Text(l.name),
                      ))
                  .toList(),
              onChanged: onLeagueChanged,
              validator: (v) =>
                  v == null ? 'Selecciona la liga o torneo.' : null,
            ),
            const SizedBox(height: 16),

            // ── Venue ──────────────────────────────────────────────────────
            LabeledTextField(
              label: 'Sede',
              controller: venueController,
              hint: 'Estadio o cancha',
              prefixIcon: const Icon(Icons.location_on_outlined),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa la sede del partido.'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Notes ──────────────────────────────────────────────────────
            _SectionLabel('Notas adicionales'),
            const SizedBox(height: 10),
            TextFormField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '📝 Información extra (opcional)',
              ),
            ),
            const SizedBox(height: 32),

            // ── Buttons ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isSubmitting
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryColor),
                        )
                      : ElevatedButton(
                          onPressed: onSubmit,
                          child: const Text('Crear Partido'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SportCard({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.white,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<Team> teams;
  final String? excludeId;
  final void Function(String?) onChanged;
  final String? Function(String?) validator;

  const _TeamDropdown({
    required this.hint,
    required this.value,
    required this.teams,
    required this.excludeId,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final items = teams
        .where((t) => t.id != excludeId)
        .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
        .toList();

    // Reset value if it's no longer in the filtered list
    final effectiveValue =
        items.any((i) => i.value == value) ? value : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(effectiveValue),
      initialValue: effectiveValue,
      decoration: InputDecoration(hintText: hint),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class _RetryView extends StatelessWidget {
  final VoidCallback onRetry;
  const _RetryView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar la información del formulario.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
