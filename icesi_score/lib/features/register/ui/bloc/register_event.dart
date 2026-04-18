abstract class RegisterEvent {
  const RegisterEvent();
}

class RegisterSubmittedEvent extends RegisterEvent {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String university;

  const RegisterSubmittedEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.university,
  });
}
