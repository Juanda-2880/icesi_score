abstract class SetPasswordEvent {
  const SetPasswordEvent();
}

class SetPasswordSubmittedEvent extends SetPasswordEvent {
  final String newPassword;
  const SetPasswordSubmittedEvent(this.newPassword);
}
