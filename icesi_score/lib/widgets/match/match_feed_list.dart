import 'package:flutter/material.dart';
import '../../features/match/domain/entities/match.dart';
import 'match_card.dart';

const _kAvatarColors = [
  Color(0xFF4343D8),
  Color(0xFFFF8C42),
  Color(0xFF6C63FF),
  Color(0xFF2ECC71),
  Color(0xFFE74C3C),
  Color(0xFF3498DB),
];

Color _teamColor(String teamId) =>
    _kAvatarColors[teamId.hashCode.abs() % _kAvatarColors.length];

String _teamInitials(String name) =>
    name.substring(0, name.length.clamp(0, 2)).toUpperCase();

class MatchFeedList extends StatelessWidget {
  final List<Match> matches;
  final Function(String matchId) onMatchTap;
  final Future<void> Function()? onRefresh;

  const MatchFeedList({
    super.key,
    required this.matches,
    required this.onMatchTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final list = matches.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(
                  child: Text(
                    'No hay partidos disponibles',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
            ],
          )
        : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: matches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _MatchListItem(
              match: matches[i],
              onTap: () => onMatchTap(matches[i].id),
            ),
          );

    if (onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: list);
    }
    return list;
  }
}

class _MatchListItem extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;

  const _MatchListItem({required this.match, required this.onTap});

  String get _eyebrowLabel {
    switch (match.status) {
      case 'IN_PROGRESS':
        return 'LIVE';
      case 'FINISHED':
        return 'Terminado';
      default:
        return match.matchTime ?? '--:--';
    }
  }

  String? get _score {
    if (match.homeScore == null || match.awayScore == null) return null;
    return '${match.homeScore} - ${match.awayScore}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _eyebrowLabel,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 4),
        MatchCard(
          tournamentName: match.leagueName,
          localTeamName: match.homeTeamName,
          localTeamInitials: _teamInitials(match.homeTeamName),
          localTeamColor: _teamColor(match.homeTeamId),
          awayTeamName: match.awayTeamName,
          awayTeamInitials: _teamInitials(match.awayTeamName),
          awayTeamColor: _teamColor(match.awayTeamId),
          status: match.status,
          time: match.matchTime,
          score: _score,
          onTap: onTap,
        ),
      ],
    );
  }
}
