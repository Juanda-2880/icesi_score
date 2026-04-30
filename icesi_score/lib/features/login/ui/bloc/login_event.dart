abstract class LoginEvent {
  const LoginEvent();
}

class LoginSubmittedEvent extends LoginEvent {
  final String email;
  final String password;

  const LoginSubmittedEvent({
    required this.email,
    required this.password,
  });
}
