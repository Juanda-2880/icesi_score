import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/usecases/delete_account_usecase.dart';
import 'delete_event.dart';
import 'delete_state.dart';

class DeleteBloc extends Bloc<DeleteEvent, DeleteState> {
  final DeleteAccountUseCase _deleteAccount;
  final String _userId;

  DeleteBloc(this._deleteAccount, this._userId)
      : super(const DeleteInitialState()) {
    on<DeleteAccountRequestedEvent>(_onDeleteRequested);
  }

  Future<void> _onDeleteRequested(
    DeleteAccountRequestedEvent event,
    Emitter<DeleteState> emit,
  ) async {
    emit(const DeletingState());
    try {
      await _deleteAccount(id: _userId);
      emit(const DeleteSuccessState());
    } on Exception catch (e) {
      emit(DeleteFailureState(e.toString()));
    }
  }
}
