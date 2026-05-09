import '../../domain/entities/match.dart';

abstract class MatchFeedState {
  const MatchFeedState();
}

class MatchFeedLoadingState extends MatchFeedState {
  const MatchFeedLoadingState();
}

class MatchFeedLoadedState extends MatchFeedState {
  final List<Match> matches;
  const MatchFeedLoadedState(this.matches);
}

class MatchFeedErrorState extends MatchFeedState {
  final String message;
  const MatchFeedErrorState(this.message);
}
