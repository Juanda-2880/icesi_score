import 'dart:async';
import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../amplifyconfiguration.dart' show wsBaseUrl;
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/live_badge.dart';
import '../../../../widgets/common/team_avatar.dart';
import '../../../../widgets/match/soccer_event_card.dart';
import '../../../../widgets/match/team_helpers.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/entities/soccer_event.dart';
import '../bloc/match_detail_bloc.dart';
import '../bloc/match_detail_event.dart';
import '../bloc/match_detail_state.dart';

class MatchDetailScreen extends StatefulWidget {
  final Match match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  Timer? _clockTimer;
  Duration _elapsed = Duration.zero;
  final Set<String> _expandedIds = {};
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    context.read<MatchDetailBloc>().add(MatchDetailStartedEvent(widget.match));
    if (widget.match.status == 'IN_PROGRESS') (() async => await _connectWs())();
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
            if (msg['type'] != 'SOCCER_EVENT') return;
            final event = msg['event'] as Map<String, dynamic>?;
            final score = msg['newScore'] as Map<String, dynamic>?;
            if (event == null) return;
            final newHomeScore = (score?['homeScore'] as num?)?.toInt();
            final newAwayScore = (score?['awayScore'] as num?)?.toInt();
            context.read<MatchDetailBloc>().add(MatchEventReceivedEvent(
                  _parseSoccerEvent(event, widget.match.id),
                  newHomeScore: newHomeScore,
                  newAwayScore: newAwayScore,
                ));
          } catch (_) {}
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  void _startClock(MatchPeriod period) {
    _clockTimer?.cancel();
    _elapsed = DateTime.now().difference(period.startTime);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(period.startTime);
      });
    });
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  @override
  void dispose() {
    _stopClock();
    _channel?.sink.close();
    super.dispose();
  }

  String _formatClock() {
    final m = _elapsed.inMinutes;
    final s = _elapsed.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  SoccerEvent _parseSoccerEvent(Map<String, dynamic> e, String matchId) {
    return SoccerEvent(
      id: e['id'] as String,
      matchId: matchId,
      eventType: e['eventType'] as String,
      minute: (e['minute'] as num).toInt(),
      mainPlayerId: e['mainPlayerId'] as String?,
      playerName: e['playerName'] as String?,
      teamId: e['teamId'] as String?,
      teamName: e['teamName'] as String?,
      scoreAtMoment: e['scoreAtMoment'] as String?,
      parentEventId: e['parentEventId'] as String?,
      secondaryPlayerName: e['secondaryPlayerName'] as String?,
      note: e['note'] as String?,
    );
  }

  Future<void> _onRefresh() async {
    context
        .read<MatchDetailBloc>()
        .add(const MatchDetailRefreshRequestedEvent());
    await context
        .read<MatchDetailBloc>()
        .stream
        .firstWhere((s) => s is! MatchDetailLoadingState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MatchDetailBloc, MatchDetailState>(
        listener: (_, state) {
          if (state is MatchDetailLoadedState) {
            if (state.match.status == 'IN_PROGRESS' &&
                state.activePeriod != null) {
              _startClock(state.activePeriod!);
            } else {
              _stopClock();
            }
          }
        },
        builder: (_, state) {
          if (state is MatchDetailLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MatchDetailErrorState) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }
          if (state is MatchDetailLoadedState) {
            return _Body(
              state: state,
              elapsed: _elapsed,
              clockLabel: _formatClock(),
              expandedIds: _expandedIds,
              onToggleExpand: _toggleExpand,
              onRefresh: _onRefresh,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _Body — stateless delegate so the clock setState only redraws the header
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  final MatchDetailLoadedState state;
  final Duration elapsed;
  final String clockLabel;
  final Set<String> expandedIds;
  final void Function(String) onToggleExpand;
  final Future<void> Function() onRefresh;

  const _Body({
    required this.state,
    required this.elapsed,
    required this.clockLabel,
    required this.expandedIds,
    required this.onToggleExpand,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final match = state.match;
    final events = state.events;

    // Separate ASSIST events and index them by parentEventId
    final assistMap = <String, SoccerEvent>{};
    final mainEvents = <SoccerEvent>[];
    for (final e in events) {
      if (e.eventType == 'ASSIST' && e.parentEventId != null) {
        assistMap[e.parentEventId!] = e;
      } else {
        mainEvents.add(e);
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ScoreHeader(
            match: match,
            clockLabel: clockLabel,
          ),
          const SizedBox(height: 24),
          _EventsSection(
            match: match,
            mainEvents: mainEvents,
            assistMap: assistMap,
            expandedIds: expandedIds,
            onToggleExpand: onToggleExpand,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Score header
// ---------------------------------------------------------------------------

class _ScoreHeader extends StatelessWidget {
  final Match match;
  final String clockLabel;

  const _ScoreHeader({required this.match, required this.clockLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Nav row — replaces AppBar
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
            // Score block
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _TeamColumn(
                        isHome: true,
                        teamName: match.homeTeamName,
                        align: CrossAxisAlignment.start,
                      ),
                      Expanded(
                          child: _CenterDisplay(
                              match: match, clockLabel: clockLabel)),
                      _TeamColumn(
                        isHome: false,
                        teamName: match.awayTeamName,
                        align: CrossAxisAlignment.end,
                      ),
                    ],
                  ),
                  if (match.status == 'SCHEDULED' && match.venue != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      match.venue!,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final bool isHome;
  final String teamName;
  final CrossAxisAlignment align;

  const _TeamColumn({
    required this.isHome,
    required this.teamName,
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
            radius: 28,
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            textAlign: align == CrossAxisAlignment.start
                ? TextAlign.left
                : TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterDisplay extends StatelessWidget {
  final Match match;
  final String clockLabel;

  const _CenterDisplay({required this.match, required this.clockLabel});

  @override
  Widget build(BuildContext context) {
    switch (match.status) {
      case 'IN_PROGRESS':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LiveBadge(),
            const SizedBox(height: 6),
            Text(
              '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
              style: const TextStyle(
                color: AppTheme.appYellow,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              clockLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        );

      case 'FINISHED':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Final',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        );

      default: // SCHEDULED
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              match.matchDate ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              match.matchTime ?? '--:--',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Events section
// ---------------------------------------------------------------------------

class _EventsSection extends StatelessWidget {
  final Match match;
  final List<SoccerEvent> mainEvents;
  final Map<String, SoccerEvent> assistMap;
  final Set<String> expandedIds;
  final void Function(String) onToggleExpand;

  const _EventsSection({
    required this.match,
    required this.mainEvents,
    required this.assistMap,
    required this.expandedIds,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Row(
            children: [
              Text('⏱', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'Recent Events',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 0.5, color: Colors.white12),
          const SizedBox(height: 6),
          if (match.status == 'SCHEDULED')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'El partido aún no ha comenzado.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            )
          else if (mainEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No hay eventos registrados aún.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            )
          else
            // mainEvents is newest-first; skip(i+1) = events older than current
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mainEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = mainEvents[i];
                final isDoubleYellow = e.eventType == 'YELLOW_CARD' &&
                    e.mainPlayerId != null &&
                    mainEvents.skip(i + 1).any((ev) =>
                        ev.eventType == 'YELLOW_CARD' &&
                        ev.mainPlayerId == e.mainPlayerId);
                return SoccerEventCard(
                  key: ValueKey(e.id),
                  event: e,
                  assist: e.eventType == 'GOAL' ? assistMap[e.id] : null,
                  isDoubleYellow: isDoubleYellow,
                  isExpanded: expandedIds.contains(e.id),
                  onTap: () => onToggleExpand(e.id),
                );
              },
            ),
        ],
        ),
      ),
    );
  }
}
