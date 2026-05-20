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

// Pre-wired hook (kept for future use).
class VolleyballEventReceivedEvent extends VolleyballDetailEvent {
  final VolleyballEvent event;
  const VolleyballEventReceivedEvent(this.event);
}

// Incremental WS update: carries the raw VOLLEYBALL_EVENT message payload.
class VolleyballDetailWsEventReceivedEvent extends VolleyballDetailEvent {
  final Map<String, dynamic> wsMessage;
  const VolleyballDetailWsEventReceivedEvent(this.wsMessage);
}
