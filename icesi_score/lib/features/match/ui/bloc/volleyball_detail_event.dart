import '../../domain/entities/match.dart';
import '../../domain/entities/volleyball_event.dart';

abstract class VolleyballDetailEvent {
  const VolleyballDetailEvent();
}

class VolleyballDetailStartedEvent extends VolleyballDetailEvent {
  final Match match;
  const VolleyballDetailStartedEvent(this.match);
}

class VolleyballDetailRefreshRequestedEvent extends VolleyballDetailEvent {
  const VolleyballDetailRefreshRequestedEvent();
}

// Hook for US-11/US-16 WebSocket broadcast — handler wired but unused until then.
class VolleyballEventReceivedEvent extends VolleyballDetailEvent {
  final VolleyballEvent event;
  const VolleyballEventReceivedEvent(this.event);
}
