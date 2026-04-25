abstract class CreateAdminEvent {
  const CreateAdminEvent();
}

class CreateAdminSubmittedEvent extends CreateAdminEvent {
  final String fullName;
  final String email;
  final String phone;
  final String university;

  const CreateAdminSubmittedEvent({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.university,
  });
}
