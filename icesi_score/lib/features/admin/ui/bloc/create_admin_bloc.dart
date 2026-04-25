import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/usecases/create_admin_usecase.dart';
import 'create_admin_event.dart';
import 'create_admin_state.dart';

class CreateAdminBloc extends Bloc<CreateAdminEvent, CreateAdminState> {
  final CreateAdminUseCase _createAdminUseCase;

  CreateAdminBloc(this._createAdminUseCase) : super(const CreateAdminInitialState()) {
    on<CreateAdminSubmittedEvent>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    CreateAdminSubmittedEvent event,
    Emitter<CreateAdminState> emit,
  ) async {
    emit(const CreateAdminLoadingState());
    try {
      await _createAdminUseCase(
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        university: event.university,
      );
      emit(const CreateAdminSuccessState());
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(CreateAdminFailureState(message));
    }
  }
}
