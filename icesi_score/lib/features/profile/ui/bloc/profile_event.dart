abstract class ProfileEvent {
  const ProfileEvent();
}

class ProfileSaveRequestedEvent extends ProfileEvent {
  final String fullName;
  final String phone;
  final String university;

  const ProfileSaveRequestedEvent({
    required this.fullName,
    required this.phone,
    required this.university,
  });
}
