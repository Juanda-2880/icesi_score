import 'package:flutter/material.dart';
import 'package:icesi_score/widgets/common/live_badge.dart';
import 'package:icesi_score/widgets/common/team_avatar.dart';

class MatchCard extends StatelessWidget{
  final String tournamentName;

  //Local Team Data
  final String localTeamName;
  final String localTeamInitials;
  final Color localTeamColor;

  // Away Team Data
  final String awayTeamName;
  final String awayTeamInitials;
  final Color awayTeamColor;

  // Match State
  final bool isLive;
  final String? time; // Ej: "16:00"
  final String? score; // Ej: "2 - 1"

  const MatchCard({
    super.key,
    required this.tournamentName,
    required this.localTeamName,
    required this.localTeamInitials,
    required this.localTeamColor,
    required this.awayTeamName,
    required this.awayTeamInitials,
    required this.awayTeamColor,
    this.isLive = false,
    this.time,
    this.score,
  });

  @override
  Widget build(BuildContext context){
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2E),
        borderRadius: BorderRadius.circular(16.0)
      ),
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
                style: const  TextStyle(
                  color: Colors.white54,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),
          const SizedBox(height: 16.0,),

          // Second Row: Teams and Time or Match Score
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Local Team (Left)
              Expanded(
                child: _buildTeamLayout(
                  name: localTeamName,
                  initials: localTeamInitials,
                  color: localTeamColor,
                  isLocal: true, // El avatar va a la izquierda
                ),
              ),
              //2. Center (Time or LIVE Match Score)
              Expanded(
                child: Center(
                  child: isLive ? _buildLiveScore() : _buildScheduledTime(),
                ),
              ),
              
              // 3. Away Team (Right)
              Expanded(
                child: _buildTeamLayout(
                  name: awayTeamName,
                  initials: awayTeamInitials,
                  color: awayTeamColor,
                  isLocal: false,
                ),
              )
            ],
          )

        ],
      ),
    );
  }

  // Private Construction Methods 

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
          height: 1.2
        ),
      )
    );

    // If it's local: [Avatar] - [Text]
    // If it's away: [Text] - [Avatar]
    return Row(
      mainAxisAlignment: isLocal ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: isLocal
        ? [avatar, const SizedBox(width: 12.0), text]
        : [text, const SizedBox(width: 12.0), avatar],
    );
  }

  Widget _buildLiveScore(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LiveBadge(),
        const SizedBox(height: 4.0,),
        Text(
          score ?? "0 - 0",
          style: const TextStyle(
            color: Color(0xFFF5A623),
            fontSize: 20.0,
            fontWeight: FontWeight.bold
          ),
        )
      ],
    );
  }

  Widget _buildScheduledTime(){
    return Text(
      time ?? "--:--",
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16.0,
        fontWeight: FontWeight.w600
      ),
    );
  }
}