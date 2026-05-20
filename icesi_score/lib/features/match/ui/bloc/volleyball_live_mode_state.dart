import '../../domain/entities/lineup_player.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/volleyball_event.dart';
import '../../domain/entities/volleyball_set.dart';

abstract class VolleyballLiveModeState {
  const VolleyballLiveModeState();
}

class VolleyballLiveModeLoadingState extends VolleyballLiveModeState {
  const VolleyballLiveModeLoadingState();
}

class VolleyballLiveModeLoadedState extends VolleyballLiveModeState {
  final Match match;
  final List<LineupPlayer> lineup;
  final VolleyballSet? activeSet;
  final List<VolleyballSet> closedSets;
  final List<VolleyballEvent> recentEvents;
  final bool isSubmitting;

  const VolleyballLiveModeLoadedState({
    required this.match,
    required this.lineup,
    this.activeSet,
    this.closedSets = const [],
    this.recentEvents = const [],
    this.isSubmitting = false,
  });

  int get nextSetNumber => closedSets.length + (activeSet != null ? 1 : 0) + 1;

  VolleyballLiveModeLoadedState copyWith({
    Match? match,
    List<LineupPlayer>? lineup,
    VolleyballSet? activeSet,
    List<VolleyballSet>? closedSets,
    List<VolleyballEvent>? recentEvents,
    bool? isSubmitting,
    bool clearActiveSet = false,
  }) =>
      VolleyballLiveModeLoadedState(
        match: match ?? this.match,
        lineup: lineup ?? this.lineup,
        activeSet: clearActiveSet ? null : (activeSet ?? this.activeSet),
        closedSets: closedSets ?? this.closedSets,
        recentEvents: recentEvents ?? this.recentEvents,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class VolleyballLiveModeSubmitSuccessState extends VolleyballLiveModeState {
  final String message;
  const VolleyballLiveModeSubmitSuccessState(this.message);
}

class VolleyballLiveModeSubmitErrorState extends VolleyballLiveModeState {
  final String message;
  const VolleyballLiveModeSubmitErrorState(this.message);
}

class VolleyballLiveModeErrorState extends VolleyballLiveModeState {
  final String message;
  const VolleyballLiveModeErrorState(this.message);
}
