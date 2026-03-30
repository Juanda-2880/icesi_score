// lib/screens/test_screen.dart

import 'package:flutter/material.dart';
import '../widgets/common/team_avatar.dart';
import '../widgets/common/live_badge.dart';
import '../widgets/match/match_card.dart';

// REGLA DEL PROFE: Como es una "Screen", debe ser StatefulWidget
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Un color de fondo oscuro provisional para ver bien las tarjetas
      backgroundColor: const Color(0xFF121212), 
      appBar: AppBar(
        title: const Text('Playground de Componentes'),
        backgroundColor: const Color(0xFF2A2B2E),
        foregroundColor: Colors.white,
      ),
      // Usamos ListView para poder hacer scroll si agregamos muchos componentes
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Átomos',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // --- PRUEBA DE ÁTOMOS ---
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TeamAvatar(
                initials: 'UI',
                backgroundColor: Color(0xFF4A61DD), // Azul Icesi
              ),
              TeamAvatar(
                initials: 'JA',
                backgroundColor: Color(0xFFE55353), // Rojo Javeriana
              ),
              LiveBadge(),
            ],
          ),
          
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          const Text(
            'Moléculas (MatchCard)',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // --- PRUEBA DE MATCHCARD: PARTIDO PROGRAMADO ---
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

          // --- PRUEBA DE MATCHCARD: PARTIDO EN VIVO ---
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