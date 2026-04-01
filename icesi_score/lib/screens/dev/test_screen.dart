import 'package:flutter/material.dart';
import '../../widgets/common/team_avatar.dart';
import '../../widgets/common/live_badge.dart';
import '../../widgets/match/match_card.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Playground de Componentes'),
        backgroundColor: const Color(0xFF2A2B2E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Atomos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TeamAvatar(
                initials: 'UI',
                backgroundColor: Color(0xFF4A61DD),
              ),
              TeamAvatar(
                initials: 'JA',
                backgroundColor: Color(0xFFE55353),
              ),
              LiveBadge(),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Moleculas (MatchCard)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const MatchCard(
            tournamentName: 'Copa Icesi',
            localTeamName: 'Univ. Icesi',
            localTeamInitials: 'UI',
            localTeamColor: Color(0xFF4A61DD),
            awayTeamName: 'Javeriana Cali',
            awayTeamInitials: 'JA',
            awayTeamColor: Color(0xFFE55353),
            isLive: false,
            time: '16:00',
          ),
          const SizedBox(height: 16),
          const MatchCard(
            tournamentName: 'Copa Icesi',
            localTeamName: 'UAO',
            localTeamInitials: 'UA',
            localTeamColor: Color(0xFF4A61DD),
            awayTeamName: 'San Buenaventura',
            awayTeamInitials: 'SB',
            awayTeamColor: Color(0xFFE55353),
            isLive: true,
            score: '2 - 1',
          ),
        ],
      ),
    );
  }
}