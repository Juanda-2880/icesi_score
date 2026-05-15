import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_period.dart';
import '../../domain/entities/soccer_event.dart';

abstract class LiveModeState {
  const LiveModeState();
}

class LiveModeLoadingState extends LiveModeState {
  const LiveModeLoadingState();
}

class LiveModeLoadedState extends LiveModeState {
  final Match match;
  final List<LineupPlayer> lineup;
  final List<SoccerEvent> events;
  final MatchPeriod? activePeriod;
  final int homeScore;
  final int awayScore;
  final bool isSubmitting;

  const LiveModeLoadedState({
    required this.match,
    required this.lineup,
    required this.events,
    this.activePeriod,
    required this.homeScore,
    required this.awayScore,
    this.isSubmitting = false,
  });

  // Goals for this match that do not yet have an ASSIST linked
  List<SoccerEvent> get unassistedGoals {
    final assistedGoalIds = events
        .where((e) => e.eventType == 'ASSIST' && e.parentEventId != null)
        .map((e) => e.parentEventId!)
        .toSet();
    return events
        .where((e) => e.eventType == 'GOAL' && !assistedGoalIds.contains(e.id))
        .toList();
  }

  LiveModeLoadedState copyWith({
    List<LineupPlayer>? lineup,
    List<SoccerEvent>? events,
    int? homeScore,
    int? awayScore,
    bool? isSubmitting,
  }) =>
      LiveModeLoadedState(
        match: match,
        lineup: lineup ?? this.lineup,
        events: events ?? this.events,
        activePeriod: activePeriod,
        homeScore: homeScore ?? this.homeScore,
        awayScore: awayScore ?? this.awayScore,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class LiveModeSubmitSuccessState extends LiveModeState {
  final String message;
  const LiveModeSubmitSuccessState(this.message);
}

class LiveModeSubmitErrorState extends LiveModeState {
  final String message;
  const LiveModeSubmitErrorState(this.message);
}

class LiveModeErrorState extends LiveModeState {
  final String message;
  const LiveModeErrorState(this.message);
}
