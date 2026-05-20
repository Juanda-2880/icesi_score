import '../../domain/entities/match.dart';

abstract class LiveModeEvent {
  const LiveModeEvent();
}

class LiveModeStartedEvent extends LiveModeEvent {
  final Match match;
  const LiveModeStartedEvent(this.match);
}

class LiveModeEventSubmittedEvent extends LiveModeEvent {
  final String eventType;
  final String mainPlayerId;
  final int eventMinute;
  final String? secondaryPlayerId;
  final String? parentEventId;
  final String? assistPlayerId;
  final String? note;

  const LiveModeEventSubmittedEvent({
    required this.eventType,
    required this.mainPlayerId,
    required this.eventMinute,
    this.secondaryPlayerId,
    this.parentEventId,
    this.assistPlayerId,
    this.note,
  });
}

class LiveModeWsEventReceivedEvent extends LiveModeEvent {
  final Map<String, dynamic> wsMessage;
  const LiveModeWsEventReceivedEvent(this.wsMessage);
}

class StartPeriodEvent extends LiveModeEvent {
  final String periodLabel;
  const StartPeriodEvent(this.periodLabel);
}

class EndPeriodEvent extends LiveModeEvent {
  final String periodId;
  const EndPeriodEvent(this.periodId);
}

class FinishMatchEvent extends LiveModeEvent {
  const FinishMatchEvent();
}
