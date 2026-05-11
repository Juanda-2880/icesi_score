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
  final bool isAdmin;
  final void Function(Match)? onEditTap;
  final void Function(Match)? onDeleteTap;

  const MatchFeedList({
    super.key,
    required this.matches,
    required this.onMatchTap,
    this.onRefresh,
    this.isAdmin = false,
    this.onEditTap,
    this.onDeleteTap,
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
              isAdmin: isAdmin,
              onEditTap: onEditTap != null ? () => onEditTap!(matches[i]) : null,
              onDeleteTap:
                  onDeleteTap != null ? () => onDeleteTap!(matches[i]) : null,
            ),
          );

    if (onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: list);
    }
    return list;
  }
}

// ---------------------------------------------------------------------------
// Swipeable list item — StatefulWidget justified for local animation state
// ---------------------------------------------------------------------------

class _MatchListItem extends StatefulWidget {
  final Match match;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const _MatchListItem({
    required this.match,
    required this.onTap,
    required this.isAdmin,
    this.onEditTap,
    this.onDeleteTap,
  });

  @override
  State<_MatchListItem> createState() => _MatchListItemState();
}

class _MatchListItemState extends State<_MatchListItem>
    with SingleTickerProviderStateMixin {
  static const double _revealWidth = 140.0;

  late final AnimationController _controller;
  late final Animation<double> _offsetAnim;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _offsetAnim = Tween<double>(begin: 0, end: -_revealWidth).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isOpen = !_isOpen);
  }

  void _close() {
    if (_isOpen) {
      _controller.reverse();
      setState(() => _isOpen = false);
    }
  }

  String get _eyebrowLabel {
    switch (widget.match.status) {
      case 'IN_PROGRESS':
        return 'LIVE';
      case 'FINISHED':
        return 'Terminado';
      default:
        return widget.match.matchTime ?? '--:--';
    }
  }

  String? get _score {
    if (widget.match.homeScore == null || widget.match.awayScore == null) {
      return null;
    }
    return '${widget.match.homeScore} - ${widget.match.awayScore}';
  }

  @override
  Widget build(BuildContext context) {
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _eyebrowLabel,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 4),
        MatchCard(
          tournamentName: widget.match.leagueName,
          localTeamName: widget.match.homeTeamName,
          localTeamInitials: _teamInitials(widget.match.homeTeamName),
          localTeamColor: _teamColor(widget.match.homeTeamId),
          awayTeamName: widget.match.awayTeamName,
          awayTeamInitials: _teamInitials(widget.match.awayTeamName),
          awayTeamColor: _teamColor(widget.match.awayTeamId),
          status: widget.match.status,
          time: widget.match.matchTime,
          score: _score,
          onTap: () {
            _close();
            widget.onTap();
          },
        ),
      ],
    );

    if (!widget.isAdmin) return card;

    final isScheduled = widget.match.status == 'SCHEDULED';

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! < -8) {
          if (!_isOpen) _toggle();
        } else if (details.primaryDelta != null && details.primaryDelta! > 8) {
          if (_isOpen) _toggle();
        }
      },
      child: Stack(
        children: [
          // Action buttons (revealed behind the card)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _revealWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionButton(
                      label: 'Editar',
                      color: const Color(0xFF6C63FF),
                      enabled: isScheduled,
                      onTap: isScheduled
                          ? () {
                              _close();
                              widget.onEditTap?.call();
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Eliminar',
                      color: const Color(0xFFFF4444),
                      enabled: isScheduled,
                      onTap: isScheduled
                          ? () {
                              _close();
                              widget.onDeleteTap?.call();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Card sliding left
          AnimatedBuilder(
            animation: _offsetAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(_offsetAnim.value, 0),
              child: child,
            ),
            child: card,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: effectiveColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
