import 'package:flutter/material.dart';

import '../../features/match/domain/entities/lineup_player.dart';
import '../../theme/app_theme.dart';
import '../match/team_helpers.dart';

// Volleyball court positions: map position number (1-6) to fractional (x, y)
// Standard volleyball rotation layout on a half-court:
//   Back row:  4(left)  3(center)  2(right)    → y ≈ 0.75
//   Front row: 5(left)  6(center)  1(right)    → y ≈ 0.25
const Map<String, Offset> _kCourtPositions = {
  '1': Offset(0.80, 0.75),
  '2': Offset(0.80, 0.25),
  '3': Offset(0.50, 0.25),
  '4': Offset(0.20, 0.25),
  '5': Offset(0.20, 0.75),
  '6': Offset(0.50, 0.75),
};

const double _kBubbleRadius = 20.0;

class VolleyballCourtWidget extends StatelessWidget {
  final List<LineupPlayer> lineup;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final void Function(LineupPlayer) onPlayerTap;
  final VoidCallback onHomeRotate;
  final VoidCallback onAwayRotate;
  final bool isSubmitting;

  const VolleyballCourtWidget({
    super.key,
    required this.lineup,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.onPlayerTap,
    required this.onHomeRotate,
    required this.onAwayRotate,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final homePlayers = lineup
        .where((p) =>
            p.teamId == homeTeamId &&
            (p.status == 'STARTER' || p.status == 'ON_FIELD'))
        .toList();

    final awayPlayers = lineup
        .where((p) =>
            p.teamId != homeTeamId &&
            (p.status == 'STARTER' || p.status == 'ON_FIELD'))
        .toList();

    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      // Each half is square; full court = 2 halves + net area
      final halfH = w * 0.55;
      final courtH = halfH * 2 + 12; // 12 px net

      return Column(
        children: [
          // Away rotation button
          _RotationButton(
            label: 'Away Rotation',
            onPressed: isSubmitting ? null : onAwayRotate,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: w,
            height: courtH,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(w, courtH),
                  painter: _CourtPainter(halfH: halfH),
                ),
                // Away team — top half (positions mirrored vertically)
                ..._buildBubbles(
                  awayPlayers,
                  w,
                  halfH,
                  isHome: false,
                  yOffset: 0,
                ),
                // Home team — bottom half
                ..._buildBubbles(
                  homePlayers,
                  w,
                  halfH,
                  isHome: true,
                  yOffset: halfH + 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Home rotation button
          _RotationButton(
            label: 'Home Rotation',
            onPressed: isSubmitting ? null : onHomeRotate,
          ),
          const SizedBox(height: 16),
          // Bench — two-column layout matching football style
          _VolleyballBenchWidget(
            lineup: lineup,
            homeTeamId: homeTeamId,
            homeTeamName: homeTeamName,
            awayTeamName: awayTeamName,
            onPlayerTap: onPlayerTap,
          ),
        ],
      );
    });
  }

  List<Widget> _buildBubbles(
    List<LineupPlayer> players,
    double w,
    double halfH, {
    required bool isHome,
    required double yOffset,
  }) {
    final result = <Widget>[];
    for (final player in players) {
      final posKey = player.positionCoordinate;
      if (posKey == null || !_kCourtPositions.containsKey(posKey)) continue;

      final frac = _kCourtPositions[posKey]!;
      final fracY = isHome ? frac.dy : 1.0 - frac.dy;
      final left = frac.dx * w - _kBubbleRadius;
      final top = yOffset + fracY * halfH - _kBubbleRadius;

      result.add(Positioned(
        key: ValueKey(player.playerId),
        left: left,
        top: top,
        child: _PlayerBubble(
          player: player,
          isHome: isHome,
          positionLabel: posKey,
          onTap: () => onPlayerTap(player),
        ),
      ));
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// _PlayerBubble — matches football bubble style with position badge
// ---------------------------------------------------------------------------

class _PlayerBubble extends StatelessWidget {
  final LineupPlayer player;
  final bool isHome;
  final String positionLabel;
  final VoidCallback onTap;

  const _PlayerBubble({
    required this.player,
    required this.isHome,
    required this.positionLabel,
    required this.onTap,
  });

  String get _lastName {
    final parts = player.playerName.trim().split(' ');
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final color = teamColor(isHome);

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: _kBubbleRadius,
          backgroundColor: color,
          child: Text(
            '${player.jerseyNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        // Position badge: small orange circle top-right
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: AppTheme.appYellow,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              positionLabel,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );

    final label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _lastName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [avatar, const SizedBox(height: 2), label],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RotationButton
// ---------------------------------------------------------------------------

class _RotationButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _RotationButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.rotate_right, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: const BorderSide(color: AppTheme.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VolleyballBenchWidget — two-column bench matching FootballBenchWidget style
// ---------------------------------------------------------------------------

class _VolleyballBenchWidget extends StatelessWidget {
  final List<LineupPlayer> lineup;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final void Function(LineupPlayer) onPlayerTap;

  const _VolleyballBenchWidget({
    required this.lineup,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final homeBench = lineup
        .where((p) => p.teamId == homeTeamId && p.status == 'ON_BENCH')
        .toList()
      ..sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));

    final awayBench = lineup
        .where((p) => p.teamId != homeTeamId && p.status == 'ON_BENCH')
        .toList()
      ..sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));

    if (homeBench.isEmpty && awayBench.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _BenchColumn(
            teamName: homeTeamName,
            players: homeBench,
            isHome: true,
            onPlayerTap: onPlayerTap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BenchColumn(
            teamName: awayTeamName,
            players: awayBench,
            isHome: false,
            onPlayerTap: onPlayerTap,
          ),
        ),
      ],
    );
  }
}

class _BenchColumn extends StatelessWidget {
  final String teamName;
  final List<LineupPlayer> players;
  final bool isHome;
  final void Function(LineupPlayer) onPlayerTap;

  const _BenchColumn({
    required this.teamName,
    required this.players,
    required this.isHome,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHome ? AppTheme.teamColorA : AppTheme.teamColorB;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Banca · $teamName',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        if (players.isEmpty)
          const Text(
            'Sin suplentes',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          )
        else
          ...players.map((p) {
            final row = Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withValues(alpha: 0.7),
                    child: Text(
                      '${p.jerseyNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.playerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );

            return InkWell(
              onTap: () => onPlayerTap(p),
              borderRadius: BorderRadius.circular(6),
              child: row,
            );
          }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _CourtPainter — draws the volleyball court floor
// ---------------------------------------------------------------------------

class _CourtPainter extends CustomPainter {
  final double halfH;

  const _CourtPainter({required this.halfH});

  @override
  void paint(Canvas canvas, Size size) {
    final floorPaint = Paint()..color = const Color(0xFF91481A);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final netPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    // Away half (top)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, halfH), floorPaint);
    // Home half (bottom)
    canvas.drawRect(
        Rect.fromLTWH(0, halfH + 12, size.width, halfH), floorPaint);

    // Court border — away
    canvas.drawRect(
        Rect.fromLTRB(4, 4, size.width - 4, halfH - 4), linePaint);
    // Court border — home
    canvas.drawRect(
        Rect.fromLTRB(4, halfH + 16, size.width - 4, halfH * 2 + 8),
        linePaint);

    // Net (center bar)
    final netY = halfH + 6.0;
    canvas.drawLine(Offset(0, netY), Offset(size.width, netY), netPaint);

    // 3m attack lines
    final attackOffset = halfH * 0.45;
    canvas.drawLine(
      Offset(4, halfH - attackOffset),
      Offset(size.width - 4, halfH - attackOffset),
      linePaint,
    );
    canvas.drawLine(
      Offset(4, halfH + 12 + attackOffset),
      Offset(size.width - 4, halfH + 12 + attackOffset),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_CourtPainter old) => old.halfH != halfH;
}
