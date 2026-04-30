import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/usecases/update_profile_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateProfileUseCase _updateProfile;
  final String _userId;

  ProfileBloc(this._updateProfile, this._userId)
      : super(const ProfileInitialState()) {
    on<ProfileSaveRequestedEvent>(_onSaveRequested);
  }

  Future<void> _onSaveRequested(
    ProfileSaveRequestedEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileSavingState());
    try {
      final user = await _updateProfile(
        id: _userId,
        fullName: event.fullName,
        phone: event.phone,
        university: event.university,
      );
      emit(ProfileSavedState(user));
    } on Exception catch (e) {
      emit(ProfileSaveFailureState(e.toString()));
    }
  }
}
