abstract class MatchFeedEvent {
  const MatchFeedEvent();
}

class MatchFeedStartedEvent extends MatchFeedEvent {
  const MatchFeedStartedEvent();
}

class MatchFeedSearchChangedEvent extends MatchFeedEvent {
  final String query;

  const MatchFeedSearchChangedEvent(this.query);
}
