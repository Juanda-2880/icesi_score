import '../../domain/entities/match.dart';
import '../../domain/entities/soccer_event.dart';

abstract class MatchDetailEvent {
  const MatchDetailEvent();
}

class MatchDetailStartedEvent extends MatchDetailEvent {
  final Match match;
  const MatchDetailStartedEvent(this.match);
}

class MatchDetailRefreshRequestedEvent extends MatchDetailEvent {
  const MatchDetailRefreshRequestedEvent();
}

// Dispatched by MatchDetailScreen when a WebSocket SOCCER_EVENT message arrives.
class MatchEventReceivedEvent extends MatchDetailEvent {
  final SoccerEvent event;
  final int? newHomeScore;
  final int? newAwayScore;
  const MatchEventReceivedEvent(
    this.event, {
    this.newHomeScore,
    this.newAwayScore,
  });
}

// Dispatched by MatchDetailScreen when a WebSocket CLOCK_UPDATE message arrives.
class MatchClockUpdateReceivedEvent extends MatchDetailEvent {
  final String action;
  final String? periodLabel;
  final String? startTime;
  final String? periodId;

  const MatchClockUpdateReceivedEvent({
    required this.action,
    this.periodLabel,
    this.startTime,
    this.periodId,
  });
}
