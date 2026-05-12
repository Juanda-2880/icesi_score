import '../../domain/entities/match.dart';
import '../../domain/entities/volleyball_event.dart';
import '../../domain/entities/volleyball_set.dart';

abstract class VolleyballDetailState {
  const VolleyballDetailState();
}

class VolleyballDetailLoadingState extends VolleyballDetailState {
  const VolleyballDetailLoadingState();
}

class VolleyballDetailLoadedState extends VolleyballDetailState {
  final Match match;
  final List<VolleyballSet> sets;
  final List<VolleyballEvent> events;

  const VolleyballDetailLoadedState({
    required this.match,
    required this.sets,
    required this.events,
  });
}

class VolleyballDetailErrorState extends VolleyballDetailState {
  final String message;
  const VolleyballDetailErrorState(this.message);
}
