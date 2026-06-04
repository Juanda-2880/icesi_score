import 'package:get_it/get_it.dart';

import 'features/auth/data/repository/auth_repository_impl.dart';
import 'features/auth/data/source/cognito_auth_data_source.dart';
import 'features/auth/data/source/local_auth_data_source.dart';
import 'features/auth/data/source/remote_auth_data_source.dart';
import 'features/auth/data/source/secure_storage_data_source.dart';
import 'features/auth/data/source/user_profile_api_data_source.dart';
import 'features/auth/data/source/user_profile_data_source.dart';
import 'features/auth/domain/repository/auth_repository.dart';
import 'features/auth/domain/usecases/confirm_new_password_usecase.dart';
import 'features/auth/domain/usecases/confirm_sign_up_usecase.dart';
import 'features/auth/domain/usecases/create_admin_usecase.dart';
import 'features/auth/domain/usecases/delete_account_usecase.dart';
import 'features/auth/domain/usecases/get_stored_session_usecase.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/domain/usecases/sign_up_usecase.dart';
import 'features/auth/domain/usecases/update_profile_usecase.dart';
import 'features/admin/ui/bloc/create_admin_bloc.dart';
import 'features/login/ui/bloc/login_bloc.dart';
import 'features/login/ui/bloc/set_password_bloc.dart';
import 'features/match/data/repository/match_repository_impl.dart';
import 'features/match/data/source/match_api_data_source.dart';
import 'features/match/data/source/match_data_source.dart';
import 'features/match/domain/repository/match_repository.dart';
import 'features/match/domain/usecases/create_match_usecase.dart';
import 'features/match/domain/usecases/delete_match_usecase.dart';
import 'features/match/domain/usecases/end_match_period_usecase.dart';
import 'features/match/domain/usecases/finish_match_usecase.dart';
import 'features/match/domain/usecases/get_leagues_usecase.dart';
import 'features/match/domain/usecases/get_match_lineup_usecase.dart';
import 'features/match/domain/usecases/get_match_period_usecase.dart';
import 'features/match/domain/usecases/get_match_periods_usecase.dart';
import 'features/match/domain/usecases/get_matches_usecase.dart';
import 'features/match/domain/usecases/get_soccer_events_usecase.dart';
import 'features/match/domain/usecases/get_teams_usecase.dart';
import 'features/match/domain/usecases/get_volleyball_data_usecase.dart';
import 'features/match/domain/usecases/post_match_period_usecase.dart';
import 'features/match/domain/usecases/post_soccer_event_usecase.dart';
import 'features/match/domain/usecases/post_volleyball_event_usecase.dart';
import 'features/match/domain/usecases/post_volleyball_set_usecase.dart';
import 'features/match/domain/usecases/rotate_team_usecase.dart';
import 'features/match/domain/usecases/update_match_usecase.dart';
import 'features/match/ui/bloc/create_match_bloc.dart';
import 'features/match/ui/bloc/live_mode_bloc.dart';
import 'features/match/ui/bloc/match_detail_bloc.dart';
import 'features/match/ui/bloc/match_feed_bloc.dart';
import 'features/match/ui/bloc/volleyball_detail_bloc.dart';
import 'features/match/ui/bloc/volleyball_live_mode_bloc.dart';
import 'features/profile/ui/bloc/logout_bloc.dart';
import 'features/register/ui/bloc/register_bloc.dart';
import 'features/session/session_cubit.dart';
import 'features/verify/ui/bloc/verify_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
  //  Auth: data sources 
  sl.registerLazySingleton<RemoteAuthDataSource>(
    () => CognitoAuthDataSource(),
  );
  sl.registerLazySingleton<LocalAuthDataSource>(
    () => SecureStorageDataSource(),
  );
  sl.registerLazySingleton<UserProfileDataSource>(
    () => UserProfileApiDataSource(),
  );

  //  Match: data source 
  sl.registerLazySingleton<MatchDataSource>(
    () => MatchApiDataSource(),
  );

  //  Auth: repository 
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<RemoteAuthDataSource>(),
      sl<LocalAuthDataSource>(),
      sl<UserProfileDataSource>(),
    ),
  );

  //  Match: repository
  // MatchRepositoryImpl takes RemoteAuthDataSource (for getIdToken) + MatchDataSource.
  // The same RemoteAuthDataSource lazy singleton is reused here.
  sl.registerLazySingleton<MatchRepository>(
    () => MatchRepositoryImpl(
      sl<RemoteAuthDataSource>(),
      sl<MatchDataSource>(),
    ),
  );

  //  Auth: use cases
  sl.registerLazySingleton(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ConfirmSignUpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetStoredSessionUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => CreateAdminUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(
      () => ConfirmNewPasswordUseCase(sl<AuthRepository>()));

  //  Match: use cases 
  sl.registerLazySingleton(() => GetTeamsUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(() => GetLeaguesUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(() => GetMatchesUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(() => CreateMatchUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(() => UpdateMatchUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(() => DeleteMatchUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => GetSoccerEventsUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => GetMatchPeriodUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => GetMatchPeriodsUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => PostMatchPeriodUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => EndMatchPeriodUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(() => FinishMatchUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => GetVolleyballDataUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => GetMatchLineupUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => PostVolleyballSetUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => PostVolleyballEventUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(() => RotateTeamUseCase(sl<MatchRepository>()));
  sl.registerLazySingleton(
      () => PostSoccerEventUseCase(sl<MatchRepository>()));

  //  Session 
  sl.registerLazySingleton(() => SessionCubit());

  //  Auth/login/register/verify: BLoCs 
  sl.registerFactory(() => LoginBloc(sl<SignInUseCase>()));
  sl.registerFactory(() => SetPasswordBloc(sl<ConfirmNewPasswordUseCase>()));
  sl.registerFactory(() => RegisterBloc(sl<SignUpUseCase>()));
  sl.registerFactory(() => VerifyBloc(sl<ConfirmSignUpUseCase>()));

  //  Profile: BLoCs 
  // LogoutBloc is a plain factory; ProfileBloc and DeleteBloc take a runtime
  // userId resolved from SessionCubit in the route — constructed manually there.
  sl.registerFactory(() => LogoutBloc(sl<SignOutUseCase>()));

  //  Admin: BLoC
  sl.registerFactory(() => CreateAdminBloc(sl<CreateAdminUseCase>()));

  //  Match: BLoCs 
  sl.registerFactory(() => FootballFeedBloc(sl<GetMatchesUseCase>()));
  sl.registerFactory(() => VolleyballFeedBloc(sl<GetMatchesUseCase>()));
  sl.registerFactory(
    () => CreateMatchBloc(
      sl<GetTeamsUseCase>(),
      sl<GetLeaguesUseCase>(),
      sl<CreateMatchUseCase>(),
      sl<UpdateMatchUseCase>(),
      sl<DeleteMatchUseCase>(),
    ),
  );
  sl.registerFactory(
    () => MatchDetailBloc(
      sl<GetSoccerEventsUseCase>(),
      sl<GetMatchPeriodUseCase>(),
    ),
  );
  sl.registerFactory(
    () => VolleyballDetailBloc(sl<GetVolleyballDataUseCase>()),
  );
  sl.registerFactory(
    () => LiveModeBloc(
      sl<GetMatchLineupUseCase>(),
      sl<PostSoccerEventUseCase>(),
      sl<GetSoccerEventsUseCase>(),
      sl<GetMatchPeriodsUseCase>(),
      sl<PostMatchPeriodUseCase>(),
      sl<EndMatchPeriodUseCase>(),
      sl<FinishMatchUseCase>(),
    ),
  );
  sl.registerFactory(
    () => VolleyballLiveModeBloc(
      sl<GetMatchLineupUseCase>(),
      sl<GetVolleyballDataUseCase>(),
      sl<PostVolleyballSetUseCase>(),
      sl<PostVolleyballEventUseCase>(),
      sl<RotateTeamUseCase>(),
    ),
  );
}
