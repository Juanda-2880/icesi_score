import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/team_avatar.dart';
import '../../../../widgets/match/team_helpers.dart';
import '../../../../widgets/volleyball/volleyball_court_widget.dart';
import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/volleyball_set.dart';
import '../bloc/volleyball_live_mode_bloc.dart';
import '../bloc/volleyball_live_mode_event.dart';
import '../bloc/volleyball_live_mode_state.dart';
import 'volleyball_live_mode_form_dialogs.dart';

class VolleyballLiveModeScreen extends StatefulWidget {
  final Match match;

  const VolleyballLiveModeScreen({super.key, required this.match});

  @override
  State<VolleyballLiveModeScreen> createState() =>
      _VolleyballLiveModeScreenState();
}

class _VolleyballLiveModeScreenState extends State<VolleyballLiveModeScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<VolleyballLiveModeBloc>()
        .add(VolleyballLiveModeStartedEvent(widget.match));
  }

  void _onPlayerTap(
      BuildContext context, LineupPlayer player, VolleyballLiveModeLoadedState state) {
    final isBench = player.status == 'ON_BENCH';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VolleyballEventBottomSheet(
        player: player,
        isBenchPlayer: isBench,
        isHome: player.teamId == widget.match.homeTeamId,
        onEventSelected: (eventType) =>
            _onEventSelected(context, eventType, player, state,
                isBenchPlayer: isBench),
      ),
    );
  }

  void _onEventSelected(
    BuildContext context,
    String eventType,
    LineupPlayer player,
    VolleyballLiveModeLoadedState state, {
    required bool isBenchPlayer,
  }) {
    switch (eventType) {
      case 'POINT':
      case 'SERVICE_ACE':
      case 'BLOCK':
      case 'ROTATION_FAULT':
        VolleyballScoringDialog.show(
          context,
          eventType: eventType,
          player: player,
          onConfirm: () {
            context.read<VolleyballLiveModeBloc>().add(
                  VolleyballEventSubmittedEvent(
                    eventType: eventType,
                    teamId: player.teamId,
                    mainPlayerId: player.playerId,
                  ),
                );
          },
        );

      case 'SUBSTITUTION':
        if (isBenchPlayer) {
          final fieldPlayers = state.lineup
              .where((p) =>
                  p.teamId == player.teamId &&
                  (p.status == 'STARTER' || p.status == 'ON_FIELD'))
              .toList();
          VolleyballSubstitutionDialog.show(
            context,
            initiator: player,
            initiatorIsBench: true,
            selectablePlayers: fieldPlayers,
            onConfirm: ({required playerOutId, required playerInId}) {
              context.read<VolleyballLiveModeBloc>().add(
                    VolleyballEventSubmittedEvent(
                      eventType: 'SUBSTITUTION',
                      teamId: player.teamId,
                      mainPlayerId: playerOutId,
                      secondaryPlayerId: playerInId,
                    ),
                  );
            },
          );
        } else {
          final benchPlayers = state.lineup
              .where((p) =>
                  p.teamId == player.teamId && p.status == 'ON_BENCH')
              .toList();
          VolleyballSubstitutionDialog.show(
            context,
            initiator: player,
            initiatorIsBench: false,
            selectablePlayers: benchPlayers,
            onConfirm: ({required playerOutId, required playerInId}) {
              context.read<VolleyballLiveModeBloc>().add(
                    VolleyballEventSubmittedEvent(
                      eventType: 'SUBSTITUTION',
                      teamId: player.teamId,
                      mainPlayerId: playerOutId,
                      secondaryPlayerId: playerInId,
                    ),
                  );
            },
          );
        }

      case 'NOTE':
        VolleyballNoteDialog.show(
          context,
          player: player,
          onConfirm: (note) {
            context.read<VolleyballLiveModeBloc>().add(
                  VolleyballEventSubmittedEvent(
                    eventType: 'NOTE',
                    teamId: player.teamId,
                    mainPlayerId: player.playerId,
                    note: note,
                  ),
                );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: BlocConsumer<VolleyballLiveModeBloc, VolleyballLiveModeState>(
        listener: (context, state) {
          if (state is VolleyballLiveModeSubmitSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ));
          } else if (state is VolleyballLiveModeSubmitErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ));
          }
        },
        buildWhen: (_, current) =>
            current is VolleyballLiveModeLoadingState ||
            current is VolleyballLiveModeLoadedState ||
            current is VolleyballLiveModeErrorState,
        builder: (context, state) {
          if (state is VolleyballLiveModeLoadingState) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (state is VolleyballLiveModeErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (state is VolleyballLiveModeLoadedState) {
            return _VolleyballLiveModeBody(
              state: state,
              match: widget.match,
              onPlayerTap: (player) => _onPlayerTap(context, player, state),
              onHomeRotate: () => context
                  .read<VolleyballLiveModeBloc>()
                  .add(RotateTeamEvent(widget.match.homeTeamId)),
              onAwayRotate: () => context
                  .read<VolleyballLiveModeBloc>()
                  .add(RotateTeamEvent(widget.match.awayTeamId)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VolleyballLiveModeBody
// ---------------------------------------------------------------------------

class _VolleyballLiveModeBody extends StatelessWidget {
  final VolleyballLiveModeLoadedState state;
  final Match match;
  final void Function(LineupPlayer) onPlayerTap;
  final VoidCallback onHomeRotate;
  final VoidCallback onAwayRotate;

  const _VolleyballLiveModeBody({
    required this.state,
    required this.match,
    required this.onPlayerTap,
    required this.onHomeRotate,
    required this.onAwayRotate,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = state.match.status == 'FINISHED';

    return CustomScrollView(
      slivers: [
        _buildHeader(),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Current set score box
              if (state.activeSet != null) ...[
                _CurrentSetScoreBox(activeSet: state.activeSet!),
                const SizedBox(height: 8),
              ],
              // Live warning banner
              if (!isFinished) ...[
                _InfoBanner(
                  color: Colors.orange,
                  icon: Icons.warning_amber,
                  text: 'Live Mode: Los cambios se actualizan instantáneamente.',
                ),
                const SizedBox(height: 8),
              ],
              // Set control button
              if (!isFinished) ...[
                _SetControlButton(
                  state: state,
                  onStartSet: () =>
                      context.read<VolleyballLiveModeBloc>().add(const StartSetEvent()),
                ),
                const SizedBox(height: 8),
              ],
              // Finished banner
              if (isFinished) ...[
                _InfoBanner(
                  color: Colors.red,
                  icon: Icons.sports_score,
                  text: 'Partido Finalizado — No se pueden registrar más eventos.',
                ),
                const SizedBox(height: 8),
              ],
              // Submitting indicator
              if (state.isSubmitting)
                const LinearProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 4),
              // Court
              IgnorePointer(
                ignoring: isFinished || state.activeSet == null,
                child: VolleyballCourtWidget(
                  lineup: state.lineup,
                  homeTeamId: match.homeTeamId,
                  homeTeamName: match.homeTeamName,
                  awayTeamName: match.awayTeamName,
                  onPlayerTap: onPlayerTap,
                  onHomeRotate: onHomeRotate,
                  onAwayRotate: onAwayRotate,
                  isSubmitting: state.isSubmitting,
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade800, Colors.grey.shade900],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top nav bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const BackButton(color: Colors.white),
                    Expanded(
                      child: Text(
                        match.leagueName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5, color: Colors.white12),
              // Team row with sets score
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _TeamSide(
                      teamName: match.homeTeamName,
                      isHome: true,
                      align: CrossAxisAlignment.start,
                    ),
                    _SetsDisplay(
                      homeSets: state.match.homeScore ?? 0,
                      awaySets: state.match.awayScore ?? 0,
                      isInProgress: state.match.status == 'IN_PROGRESS',
                    ),
                    _TeamSide(
                      teamName: match.awayTeamName,
                      isHome: false,
                      align: CrossAxisAlignment.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _TeamSide extends StatelessWidget {
  final String teamName;
  final bool isHome;
  final CrossAxisAlignment align;

  const _TeamSide({
    required this.teamName,
    required this.isHome,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          TeamAvatar(
            initials: teamInitials(teamName),
            backgroundColor: teamColor(isHome),
            radius: 24,
          ),
          const SizedBox(height: 6),
          Text(
            teamName,
            textAlign:
                align == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetsDisplay extends StatelessWidget {
  final int homeSets;
  final int awaySets;
  final bool isInProgress;

  const _SetsDisplay({
    required this.homeSets,
    required this.awaySets,
    required this.isInProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$homeSets - $awaySets',
          style: TextStyle(
            color: isInProgress ? AppTheme.appYellow : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Sets',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _CurrentSetScoreBox extends StatelessWidget {
  final VolleyballSet activeSet;

  const _CurrentSetScoreBox({required this.activeSet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      child: Column(
        children: [
          Text(
            '${activeSet.homeScore}  -  ${activeSet.awayScore}',
            style: const TextStyle(
              color: AppTheme.appYellow,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set ${activeSet.setNumber}',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SetControlButton extends StatelessWidget {
  final VolleyballLiveModeLoadedState state;
  final VoidCallback onStartSet;

  const _SetControlButton({required this.state, required this.onStartSet});

  @override
  Widget build(BuildContext context) {
    // While a set is active, do not show a button (set closes automatically)
    if (state.activeSet != null) return const SizedBox.shrink();

    final setNumber = state.closedSets.length + 1;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: state.isSubmitting ? null : onStartSet,
        icon: state.isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.sports_volleyball, size: 18),
        label: Text('Iniciar Set $setNumber'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _InfoBanner({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
