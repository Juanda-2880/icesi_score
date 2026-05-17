import 'package:flutter/material.dart';
import '../../features/match/domain/entities/lineup_player.dart';
import '../../features/match/domain/entities/soccer_event.dart';
import '../../theme/app_theme.dart';

class FootballFieldWidget extends StatelessWidget {
  final List<LineupPlayer> lineup;
  final String homeTeamId;
  final List<SoccerEvent> events;
  final void Function(LineupPlayer) onPlayerTap;

  const FootballFieldWidget({
    super.key,
    required this.lineup,
    required this.homeTeamId,
    required this.events,
    required this.onPlayerTap,
  });

  static const List<Offset> _positions = [
    Offset(0.50, 0.88), // GK
    Offset(0.80, 0.77), Offset(0.60, 0.77), Offset(0.40, 0.77), Offset(0.20, 0.77), // DEF
    Offset(0.80, 0.66), Offset(0.60, 0.66), Offset(0.40, 0.66), Offset(0.20, 0.66), // MID
    Offset(0.60, 0.55), Offset(0.40, 0.55), // FWD
  ];

  @override
  Widget build(BuildContext context) {
    final homePlayers = lineup
        .where((p) =>
            p.teamId == homeTeamId &&
            (p.status == 'STARTER' ||
                p.status == 'ON_FIELD' ||
                p.status == 'EXPELLED'))
        .toList();

    final awayPlayers = lineup
        .where((p) =>
            p.teamId != homeTeamId &&
            (p.status == 'STARTER' ||
                p.status == 'ON_FIELD' ||
                p.status == 'EXPELLED'))
        .toList();

    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = w * 1.5;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            CustomPaint(size: Size(w, h), painter: _FieldPainter()),
            ..._buildTeamBubbles(homePlayers, w, h, isHome: true),
            ..._buildTeamBubbles(awayPlayers, w, h, isHome: false),
          ],
        ),
      );
    });
  }

  List<Widget> _buildTeamBubbles(
    List<LineupPlayer> players,
    double w,
    double h, {
    required bool isHome,
  }) {
    const bubbleRadius = 20.0;
    final result = <Widget>[];
    for (var i = 0; i < players.length && i < _positions.length; i++) {
      final pos = _positions[i];
      final dy = isHome ? pos.dy : 1.0 - pos.dy;
      final topOffset = dy * h - bubbleRadius;
      final yellowCards = events
          .where((e) =>
              e.eventType == 'YELLOW_CARD' &&
              e.mainPlayerId == players[i].playerId)
          .length;
      result.add(Positioned(
        left: pos.dx * w - bubbleRadius,
        top: topOffset,
        child: _PlayerBubble(
          player: players[i],
          isHome: isHome,
          yellowCardCount: yellowCards,
          onTap: () => onPlayerTap(players[i]),
        ),
      ));
    }
    return result;
  }
}

class _PlayerBubble extends StatelessWidget {
  final LineupPlayer player;
  final bool isHome;
  final int yellowCardCount;
  final VoidCallback onTap;

  const _PlayerBubble({
    required this.player,
    required this.isHome,
    required this.yellowCardCount,
    required this.onTap,
  });

  String get _lastName {
    final parts = player.playerName.trim().split(' ');
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEffectivelyExpelled =
        player.status == 'EXPELLED' || yellowCardCount >= 2;
    final bool hasOneYellow = yellowCardCount == 1 && !isEffectivelyExpelled;

    final teamColor = isHome ? AppTheme.teamColorA : AppTheme.teamColorB;
    final bubbleColor =
        isEffectivelyExpelled ? Colors.grey.shade500 : teamColor;

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: bubbleColor,
          child: Text(
            '${player.jerseyNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        if (isEffectivelyExpelled)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 10,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )
        else if (hasOneYellow)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 10,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(2),
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

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [avatar, const SizedBox(height: 2), label],
    );

    if (isEffectivelyExpelled) {
      return IgnorePointer(child: column);
    }
    return GestureDetector(onTap: onTap, child: column);
  }
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF2E7D32),
    );

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const m = 12.0;

    canvas.drawRect(Rect.fromLTRB(m, m, w - m, h - m), line);
    canvas.drawLine(Offset(m, h * 0.5), Offset(w - m, h * 0.5), line);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.12, line);

    final penW = w * 0.55;
    final penH = h * 0.13;
    final penL = (w - penW) / 2;
    canvas.drawRect(Rect.fromLTRB(penL, m, w - penL, m + penH), line);
    canvas.drawRect(Rect.fromLTRB(penL, h - m - penH, w - penL, h - m), line);

    final goalW = w * 0.3;
    final goalH = h * 0.045;
    final goalL = (w - goalW) / 2;
    canvas.drawRect(Rect.fromLTRB(goalL, m, w - goalL, m + goalH), line);
    canvas.drawRect(Rect.fromLTRB(goalL, h - m - goalH, w - goalL, h - m), line);

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FootballBenchWidget extends StatelessWidget {
  final List<LineupPlayer> lineup;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final List<SoccerEvent> events;
  final void Function(LineupPlayer) onPlayerTap;

  const FootballBenchWidget({
    super.key,
    required this.lineup,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.events,
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _BenchColumn(
            teamName: homeTeamName,
            players: homeBench,
            isHome: true,
            events: events,
            onPlayerTap: onPlayerTap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BenchColumn(
            teamName: awayTeamName,
            players: awayBench,
            isHome: false,
            events: events,
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
  final List<SoccerEvent> events;
  final void Function(LineupPlayer) onPlayerTap;

  const _BenchColumn({
    required this.teamName,
    required this.players,
    required this.isHome,
    required this.events,
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
            final yellowCards = events
                .where((e) =>
                    e.eventType == 'YELLOW_CARD' &&
                    e.mainPlayerId == p.playerId)
                .length;
            final isEffectivelyExpelled =
                p.status == 'EXPELLED' || yellowCards >= 2;
            final hasOneYellow = yellowCards == 1 && !isEffectivelyExpelled;
            final playerColor = isEffectivelyExpelled
                ? Colors.grey.shade500
                : color.withValues(alpha: 0.7);

            final row = Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: playerColor,
                        child: Text(
                          '${p.jerseyNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isEffectivelyExpelled)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 8,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        )
                      else if (hasOneYellow)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 8,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.playerName,
                      style: TextStyle(
                        color: isEffectivelyExpelled
                            ? Colors.grey
                            : Colors.white,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );

            if (isEffectivelyExpelled) {
              return IgnorePointer(child: row);
            }
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
