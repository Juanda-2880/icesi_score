import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/entities/soccer_event.dart';

abstract class MatchDetailState {
  const MatchDetailState();
}

class MatchDetailLoadingState extends MatchDetailState {
  const MatchDetailLoadingState();
}

class MatchDetailLoadedState extends MatchDetailState {
  final Match match;
  final List<SoccerEvent> events;
  final MatchPeriod? activePeriod;

  const MatchDetailLoadedState({
    required this.match,
    required this.events,
    this.activePeriod,
  });

  MatchDetailLoadedState copyWith({
    Match? match,
    List<SoccerEvent>? events,
    MatchPeriod? activePeriod,
  }) =>
      MatchDetailLoadedState(
        match: match ?? this.match,
        events: events ?? this.events,
        activePeriod: activePeriod ?? this.activePeriod,
      );
}

class MatchDetailErrorState extends MatchDetailState {
  final String message;
  const MatchDetailErrorState(this.message);
}
