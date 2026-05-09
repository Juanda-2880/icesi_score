import 'package:flutter/material.dart';
import 'package:icesi_score/widgets/common/live_badge.dart';
import 'package:icesi_score/widgets/common/team_avatar.dart';

class MatchCard extends StatelessWidget {
  final String tournamentName;

  // Local Team Data
  final String localTeamName;
  final String localTeamInitials;
  final Color localTeamColor;

  // Away Team Data
  final String awayTeamName;
  final String awayTeamInitials;
  final Color awayTeamColor;

  // Match state: 'SCHEDULED' | 'IN_PROGRESS' | 'FINISHED'
  final String status;
  final String? time;  // shown when SCHEDULED
  final String? score; // shown when IN_PROGRESS or FINISHED

  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.tournamentName,
    required this.localTeamName,
    required this.localTeamInitials,
    required this.localTeamColor,
    required this.awayTeamName,
    required this.awayTeamInitials,
    required this.awayTeamColor,
    required this.status,
    this.time,
    this.score,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2E),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First Row: Star and Tournament
              Row(
                children: [
                  const Icon(
                    Icons.star_border_rounded,
                    color: Colors.white54,
                    size: 18.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    tournamentName,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Second Row: Teams and Center Display
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildTeamLayout(
                      name: localTeamName,
                      initials: localTeamInitials,
                      color: localTeamColor,
                      isLocal: true,
                    ),
                  ),
                  Expanded(
                    child: Center(child: _buildCenter()),
                  ),
                  Expanded(
                    child: _buildTeamLayout(
                      name: awayTeamName,
                      initials: awayTeamInitials,
                      color: awayTeamColor,
                      isLocal: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenter() {
    switch (status) {
      case 'IN_PROGRESS':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LiveBadge(),
            const SizedBox(height: 4.0),
            Text(
              score ?? '0 - 0',
              style: const TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case 'FINISHED':
        return Text(
          score ?? '0 - 0',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        );
      default:
        return Text(
          time ?? '--:--',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }

  Widget _buildTeamLayout({
    required String name,
    required String initials,
    required Color color,
    required bool isLocal,
  }) {
    final avatar = TeamAvatar(initials: initials, backgroundColor: color);

    final text = Expanded(
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );

    return Row(
      mainAxisAlignment:
          isLocal ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: isLocal
          ? [avatar, const SizedBox(width: 12.0), text]
          : [text, const SizedBox(width: 12.0), avatar],
    );
  }
}
