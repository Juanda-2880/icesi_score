import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../widgets/common/team_avatar.dart';
import '../../../../widgets/match/team_helpers.dart';
import '../../../../widgets/match/volleyball_event_card.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/volleyball_event.dart';
import '../../domain/entities/volleyball_set.dart';
import '../bloc/volleyball_detail_bloc.dart';
import '../bloc/volleyball_detail_event.dart';
import '../bloc/volleyball_detail_state.dart';

class VolleyballDetailScreen extends StatefulWidget {
  final Match match;

  const VolleyballDetailScreen({super.key, required this.match});

  @override
  State<VolleyballDetailScreen> createState() => _VolleyballDetailScreenState();
}

class _VolleyballDetailScreenState extends State<VolleyballDetailScreen> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    context
        .read<VolleyballDetailBloc>()
        .add(VolleyballDetailStartedEvent(widget.match));
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

  Future<void> _onRefresh() async {
    context
        .read<VolleyballDetailBloc>()
        .add(const VolleyballDetailRefreshRequestedEvent());
    await context
        .read<VolleyballDetailBloc>()
        .stream
        .firstWhere((s) => s is! VolleyballDetailLoadingState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<VolleyballDetailBloc, VolleyballDetailState>(
        builder: (_, state) {
          if (state is VolleyballDetailLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VolleyballDetailErrorState) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }
          if (state is VolleyballDetailLoadedState) {
            return _Body(
              state: state,
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
// _Body
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  final VolleyballDetailLoadedState state;
  final Set<String> expandedIds;
  final void Function(String) onToggleExpand;
  final Future<void> Function() onRefresh;

  const _Body({
    required this.state,
    required this.expandedIds,
    required this.onToggleExpand,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final match = state.match;
    final isScheduled = match.status == 'SCHEDULED';

    if (isScheduled) {
      return Column(
        children: [
          _ScoreHeader(match: match),
          const Expanded(
            child: Center(
              child: Text(
                'El partido aún no ha comenzado',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ScoreHeader(match: match),
          const SizedBox(height: 16),
          _CurrentSetBlock(sets: state.sets),
          const SizedBox(height: 16),
          _SetScoresCard(
            match: match,
            sets: state.sets,
          ),
          const SizedBox(height: 16),
          _EventsSection(
            events: state.events,
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

  const _ScoreHeader({required this.match});

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _TeamColumn(
                        teamId: match.homeTeamId,
                        teamName: match.homeTeamName,
                        align: CrossAxisAlignment.start,
                      ),
                      Expanded(child: _CenterDisplay(match: match)),
                      _TeamColumn(
                        teamId: match.awayTeamId,
                        teamName: match.awayTeamName,
                        align: CrossAxisAlignment.end,
                      ),
                    ],
                  ),
                  if (match.status == 'SCHEDULED' && match.venue != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      match.venue!,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
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
  final String teamId;
  final String teamName;
  final CrossAxisAlignment align;

  const _TeamColumn({
    required this.teamId,
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
            backgroundColor: teamColor(teamId),
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

  const _CenterDisplay({required this.match});

  @override
  Widget build(BuildContext context) {
    switch (match.status) {
      case 'IN_PROGRESS':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
              style: const TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sets',
              style: TextStyle(color: Colors.white54, fontSize: 13),
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
              'Sets',
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
// Current set score block (IN_PROGRESS / FINISHED only)
// ---------------------------------------------------------------------------

class _CurrentSetBlock extends StatelessWidget {
  final List<VolleyballSet> sets;

  const _CurrentSetBlock({required this.sets});

  @override
  Widget build(BuildContext context) {
    final active = sets.where((s) => s.isActive).firstOrNull;
    if (active == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2B2E),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          children: [
            Text(
              '${active.homeScore} - ${active.awayScore}',
              style: const TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set ${active.setNumber}',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Set scores card
// ---------------------------------------------------------------------------

class _SetScoresCard extends StatelessWidget {
  final Match match;
  final List<VolleyballSet> sets;

  const _SetScoresCard({required this.match, required this.sets});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🏐', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text(
                  'Set Scores',
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
            const SizedBox(height: 8),
            if (sets.isEmpty)
              const Text(
                'No hay sets registrados aún.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              )
            else
              ...sets.map((s) => _SetRow(
                    set: s,
                    homeTeamId: match.homeTeamId,
                    awayTeamId: match.awayTeamId,
                  )),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final VolleyballSet set;
  final String homeTeamId;
  final String awayTeamId;

  const _SetRow({
    required this.set,
    required this.homeTeamId,
    required this.awayTeamId,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = set.isActive;
    final homeColor = isLive ? const Color(0xFFF5A623) : teamColor(homeTeamId);
    final awayColor = isLive ? const Color(0xFFF5A623) : teamColor(awayTeamId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: isLive
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFFF5A623), width: 1),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      padding: isLive
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            'Set ${set.setNumber}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (isLive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            '${set.homeScore}',
            style: TextStyle(
              color: homeColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '  -  ',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
          Text(
            '${set.awayScore}',
            style: TextStyle(
              color: awayColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Events section
// ---------------------------------------------------------------------------

class _EventsSection extends StatelessWidget {
  final List<VolleyballEvent> events;
  final Set<String> expandedIds;
  final void Function(String) onToggleExpand;

  const _EventsSection({
    required this.events,
    required this.expandedIds,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
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
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No hay eventos registrados aún.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final e = events[i];
                  return VolleyballEventCard(
                    key: ValueKey(e.id),
                    event: e,
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
