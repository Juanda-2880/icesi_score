import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../amplifyconfiguration.dart' show wsBaseUrl;
import '../../../../theme/app_theme.dart';
import '../../../../widgets/match/football_field_widget.dart';
import '../../../../widgets/match/player_event_bottom_sheet.dart';
import '../../../../widgets/match/running_clock.dart';
import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../bloc/live_mode_bloc.dart';
import '../bloc/live_mode_event.dart';
import '../bloc/live_mode_state.dart';
import 'live_mode_form_dialogs.dart';

class LiveModeScreen extends StatefulWidget {
  final Match match;

  const LiveModeScreen({super.key, required this.match});

  @override
  State<LiveModeScreen> createState() => _LiveModeScreenState();
}

class _LiveModeScreenState extends State<LiveModeScreen> {
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    context
        .read<LiveModeBloc>()
        .add(LiveModeStartedEvent(widget.match));
    (() async => await _connectWs())();
  }

  Future<void> _connectWs() async {
    try {
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final idToken = session.userPoolTokensResult.value.idToken.raw;
      final wsUrl = '$wsBaseUrl?token=$idToken&match_id=${widget.match.id}';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (raw) {
          if (!mounted) return;
          try {
            final msg = jsonDecode(raw as String) as Map<String, dynamic>;
            if (msg['type'] == 'SOCCER_EVENT' ||
                msg['type'] == 'CLOCK_UPDATE') {
              context
                  .read<LiveModeBloc>()
                  .add(LiveModeWsEventReceivedEvent(msg));
            }
          } catch (_) {}
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _onPlayerTap(BuildContext context, LineupPlayer player,
      LiveModeLoadedState state) {
    final isBenchPlayer = player.status == 'ON_BENCH';
    final wasSubstitutedOut = isBenchPlayer &&
        state.events.any((e) =>
            e.eventType == 'SUBSTITUTION' &&
            e.mainPlayerId == player.playerId);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlayerEventBottomSheet(
        player: player,
        isHome: player.teamId == widget.match.homeTeamId,
        isBenchPlayer: isBenchPlayer,
        wasSubstitutedOut: wasSubstitutedOut,
        onEventSelected: (eventType) =>
            _onEventSelected(context, eventType, player, state,
                isBenchPlayer: isBenchPlayer),
      ),
    );
  }

  void _onEventSelected(
    BuildContext context,
    String eventType,
    LineupPlayer player,
    LiveModeLoadedState state, {
    bool isBenchPlayer = false,
  }) {
    switch (eventType) {
      case 'GOAL':
        final teamOnField = state.lineup
            .where((p) =>
                p.teamId == player.teamId &&
                (p.status == 'STARTER' || p.status == 'ON_FIELD'))
            .toList();
        GoalEventDialog.show(
          context,
          scorer: player,
          teamOnField: teamOnField,
          activePeriod: state.activePeriod,
          onConfirm: ({required int minute, String? assistPlayerId}) {
            context.read<LiveModeBloc>().add(LiveModeEventSubmittedEvent(
                  eventType: 'GOAL',
                  mainPlayerId: player.playerId,
                  eventMinute: minute,
                  assistPlayerId: assistPlayerId,
                ));
          },
        );

      case 'ASSIST':
        AssistEventDialog.show(
          context,
          assister: player,
          unassistedGoals: state.unassistedGoals,
          activePeriod: state.activePeriod,
          onConfirm: ({required int minute, required String parentEventId}) {
            context.read<LiveModeBloc>().add(LiveModeEventSubmittedEvent(
                  eventType: 'ASSIST',
                  mainPlayerId: player.playerId,
                  eventMinute: minute,
                  parentEventId: parentEventId,
                ));
          },
        );

      case 'YELLOW_CARD':
      case 'RED_CARD':
        CardEventDialog.show(
          context,
          eventType: eventType,
          player: player,
          activePeriod: state.activePeriod,
          onConfirm: ({required int minute}) {
            context.read<LiveModeBloc>().add(LiveModeEventSubmittedEvent(
                  eventType: eventType,
                  mainPlayerId: player.playerId,
                  eventMinute: minute,
                ));
          },
        );

      case 'SUBSTITUTION':
        if (isBenchPlayer) {
          final fieldPlayers = state.lineup
              .where((p) =>
                  p.teamId == player.teamId &&
                  (p.status == 'STARTER' || p.status == 'ON_FIELD'))
              .toList();
          SubstitutionEventDialog.show(
            context,
            initiator: SubstitutionInitiator.bench,
            fixedPlayer: player,
            selectablePlayers: fieldPlayers,
            activePeriod: state.activePeriod,
            onConfirm: ({
              required int minute,
              required String playerOutId,
              required String playerInId,
            }) {
              context.read<LiveModeBloc>().add(LiveModeEventSubmittedEvent(
                    eventType: 'SUBSTITUTION',
                    mainPlayerId: playerOutId,
                    eventMinute: minute,
                    secondaryPlayerId: playerInId,
                  ));
            },
          );
        } else {
          final benchPlayers = state.lineup
              .where((p) => p.teamId == player.teamId && p.status == 'ON_BENCH')
              .toList();
          SubstitutionEventDialog.show(
            context,
            initiator: SubstitutionInitiator.field,
            fixedPlayer: player,
            selectablePlayers: benchPlayers,
            activePeriod: state.activePeriod,
            onConfirm: ({
              required int minute,
              required String playerOutId,
              required String playerInId,
            }) {
              context.read<LiveModeBloc>().add(LiveModeEventSubmittedEvent(
                    eventType: 'SUBSTITUTION',
                    mainPlayerId: playerOutId,
                    eventMinute: minute,
                    secondaryPlayerId: playerInId,
                  ));
            },
          );
        }

      case 'NOTE':
        NoteEventDialog.show(
          context,
          player: player,
          activePeriod: state.activePeriod,
          onConfirm: ({required int minute, required String note}) {
            context.read<LiveModeBloc>().add(LiveModeEventSubmittedEvent(
                  eventType: 'NOTE',
                  mainPlayerId: player.playerId,
                  eventMinute: minute,
                  note: note,
                ));
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Modo Live',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: BlocConsumer<LiveModeBloc, LiveModeState>(
        listener: (context, state) {
          if (state is LiveModeSubmitSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF4CAF50),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is LiveModeSubmitErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        buildWhen: (previous, current) =>
            current is LiveModeLoadingState ||
            current is LiveModeLoadedState ||
            current is LiveModeErrorState,
        builder: (context, state) {
          if (state is LiveModeLoadingState) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryColor));
          }
          if (state is LiveModeErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (state is LiveModeLoadedState) {
            return _LiveModeBody(
              state: state,
              matchId: widget.match.id,
              homeTeamId: widget.match.homeTeamId,
              homeTeamName: widget.match.homeTeamName,
              awayTeamName: widget.match.awayTeamName,
              onPlayerTap: (player) =>
                  _onPlayerTap(context, player, state),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LiveModeBody
// ---------------------------------------------------------------------------

class _LiveModeBody extends StatelessWidget {
  final LiveModeLoadedState state;
  final String matchId;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final void Function(LineupPlayer) onPlayerTap;

  const _LiveModeBody({
    required this.state,
    required this.matchId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = state.match.status == 'FINISHED';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _ScoreHeader(
            homeTeamName: homeTeamName,
            awayTeamName: awayTeamName,
            homeScore: state.homeScore,
            awayScore: state.awayScore,
            periodLabel: state.activePeriod?.periodLabel,
          ),
          const SizedBox(height: 8),
          _ClockSection(
            state: state,
            matchId: matchId,
          ),
          if (!isFinished && state.activePeriod == null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No hay período activo. Los minutos se calcularán desde 0.',
                      style:
                          TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isFinished) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sports_score, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Partido Finalizado — No se pueden registrar más eventos.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (state.isSubmitting)
            const LinearProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          // IgnorePointer disables all player taps when match is FINISHED
          IgnorePointer(
            ignoring: isFinished,
            child: FootballFieldWidget(
              lineup: state.lineup,
              homeTeamId: homeTeamId,
              events: state.events,
              onPlayerTap: onPlayerTap,
            ),
          ),
          const SizedBox(height: 12),
          IgnorePointer(
            ignoring: isFinished,
            child: FootballBenchWidget(
              lineup: state.lineup,
              homeTeamId: homeTeamId,
              homeTeamName: homeTeamName,
              awayTeamName: awayTeamName,
              events: state.events,
              onPlayerTap: onPlayerTap,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ClockSection — StatelessWidget shell that reads BLoC state for the button,
// and mounts _RunningClock (StatefulWidget) when a period is active.
// ---------------------------------------------------------------------------

class _ClockSection extends StatelessWidget {
  final LiveModeLoadedState state;
  final String matchId;

  const _ClockSection({required this.state, required this.matchId});

  String _nextPeriodLabel() {
    if (state.closedPeriodLabels.contains('1T')) return '2T';
    return '1T';
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = state.match.status == 'FINISHED';
    final activePeriod = state.activePeriod;
    final has1TClosed = state.closedPeriodLabels.contains('1T');

    return Column(
      children: [
        // Running clock — only visible when a period is active
        if (activePeriod != null)
          RunningClock(startTime: activePeriod.startTime),

        const SizedBox(height: 8),

        // Clock button
        if (!isFinished)
          _ClockButton(
            label: _buttonLabel(activePeriod, has1TClosed),
            onPressed: () => _handleClockAction(context, activePeriod, has1TClosed),
            isLoading: state.isSubmitting,
          )
        else
          _ClockButton(
            label: 'Partido Finalizado',
            onPressed: null,
            isLoading: false,
          ),
      ],
    );
  }

  String _buttonLabel(MatchPeriod? activePeriod, bool has1TClosed) {
    if (activePeriod != null) {
      return activePeriod.periodLabel == '2T'
          ? 'Finalizar Partido'
          : 'Finalizar ${activePeriod.periodLabel == '1T' ? '1er' : '2do'} Tiempo';
    }
    if (!has1TClosed) return 'Iniciar 1er Tiempo';
    return 'Iniciar 2do Tiempo';
  }

  void _handleClockAction(
      BuildContext context, MatchPeriod? activePeriod, bool has1TClosed) {
    if (activePeriod != null) {
      if (activePeriod.periodLabel == '2T') {
        context.read<LiveModeBloc>().add(const FinishMatchEvent());
      } else {
        context
            .read<LiveModeBloc>()
            .add(EndPeriodEvent(activePeriod.id));
      }
    } else {
      context
          .read<LiveModeBloc>()
          .add(StartPeriodEvent(_nextPeriodLabel()));
    }
  }
}

// ---------------------------------------------------------------------------
// _ClockButton — purely presentational StatelessWidget
// ---------------------------------------------------------------------------

class _ClockButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ClockButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.timer, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? Colors.grey.shade700
              : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ScoreHeader
// ---------------------------------------------------------------------------

class _ScoreHeader extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final String? periodLabel;

  const _ScoreHeader({
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          if (periodLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                periodLabel!,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  homeTeamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$homeScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—',
                    style: TextStyle(color: Colors.grey, fontSize: 20)),
              ),
              Text(
                '$awayScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  awayTeamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
