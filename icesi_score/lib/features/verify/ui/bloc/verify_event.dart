abstract class VerifyEvent {
  const VerifyEvent();
}

class VerifyCodeSubmittedEvent extends VerifyEvent {
  final String email;
  final String code;

  const VerifyCodeSubmittedEvent({
    required this.email,
    required this.code,
  });
}
