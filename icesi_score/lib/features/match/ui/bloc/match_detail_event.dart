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

// Hook for US-11 WebSocket broadcast — handler is wired but unused until then.
class MatchEventReceivedEvent extends MatchDetailEvent {
  final SoccerEvent event;
  const MatchEventReceivedEvent(this.event);
}
