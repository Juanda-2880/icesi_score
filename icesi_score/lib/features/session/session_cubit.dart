import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/domain/entities/auth_user.dart';

class SessionCubit extends Cubit<AuthUser?> {
  SessionCubit() : super(null);

  void setUser(AuthUser user) => emit(user);
  void clearUser() => emit(null);
}
