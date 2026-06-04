import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide AuthUser;
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' hide AuthUser;
import 'amplifyconfiguration.dart' show amplifyconfig;
import 'theme/app_theme.dart';
import 'features/auth/domain/entities/auth_user.dart';
import 'features/auth/domain/usecases/get_stored_session_usecase.dart';
import 'features/auth/domain/usecases/update_profile_usecase.dart';
import 'features/auth/domain/usecases/delete_account_usecase.dart';
import 'features/admin/ui/bloc/create_admin_bloc.dart';
import 'features/admin/ui/screens/admin_dashboard_screen.dart';
import 'features/admin/ui/screens/create_admin_screen.dart';
import 'features/match/domain/entities/match.dart';
import 'features/match/ui/bloc/create_match_bloc.dart';
import 'features/match/ui/bloc/live_mode_bloc.dart';
import 'features/match/ui/bloc/match_detail_bloc.dart';
import 'features/match/ui/bloc/match_feed_bloc.dart';
import 'features/match/ui/bloc/match_feed_event.dart';
import 'features/match/ui/bloc/volleyball_detail_bloc.dart';
import 'features/match/ui/bloc/volleyball_live_mode_bloc.dart';
import 'features/match/ui/screens/create_match_screen.dart';
import 'features/match/ui/screens/live_mode_screen.dart';
import 'features/match/ui/screens/match_detail_screen.dart';
import 'features/match/ui/screens/volleyball_detail_screen.dart';
import 'features/match/ui/screens/volleyball_live_mode_screen.dart';
import 'features/home/ui/screens/home_screen.dart';
import 'features/login/ui/bloc/login_bloc.dart';
import 'features/login/ui/bloc/set_password_bloc.dart';
import 'features/login/ui/screens/login_screen.dart';
import 'features/login/ui/screens/set_new_password_screen.dart';
import 'features/login/ui/screens/welcome_screen.dart';
import 'features/profile/ui/bloc/delete_bloc.dart';
import 'features/profile/ui/bloc/logout_bloc.dart';
import 'features/profile/ui/bloc/profile_bloc.dart';
import 'features/profile/ui/screens/profile_screen.dart';
import 'features/register/ui/bloc/register_bloc.dart';
import 'features/register/ui/screens/register_screen.dart';
import 'features/session/session_cubit.dart';
import 'features/verify/ui/bloc/verify_bloc.dart';
import 'features/verify/ui/screens/verify_screen.dart';
import 'injection_container.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initDependencies();
  runApp(const IcesiScoreApp());
}

class IcesiScoreApp extends StatefulWidget {
  const IcesiScoreApp({super.key});

  @override
  State<IcesiScoreApp> createState() => _IcesiScoreAppState();
}

class _IcesiScoreAppState extends State<IcesiScoreApp> {
  late final Future<AuthUser?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _initApp();
  }

  Future<AuthUser?> _initApp() async {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyconfig);
    return sl<GetStoredSessionUseCase>()();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionCubit>(
      create: (_) => sl<SessionCubit>(),
      child: MaterialApp(
        title: 'IcesiScore',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routes: {
          '/welcome': (_) => const WelcomeScreen(),
          '/login': (_) => BlocProvider<LoginBloc>(
                create: (_) => sl<LoginBloc>(),
                child: const LoginScreen(),
              ),
          '/register': (_) => BlocProvider<RegisterBloc>(
                create: (_) => sl<RegisterBloc>(),
                child: const RegisterScreen(),
              ),
          '/verify': (_) => BlocProvider<VerifyBloc>(
                create: (_) => sl<VerifyBloc>(),
                child: const VerifyScreen(),
              ),
          '/routing': (ctx) {
            final user = ModalRoute.of(ctx)!.settings.arguments as AuthUser;
            return _RoutingGate(user: user);
          },
          '/home': (ctx) {
            final user = ModalRoute.of(ctx)!.settings.arguments as AuthUser;
            return MultiBlocProvider(
              providers: [
                BlocProvider<FootballFeedBloc>(
                  create: (_) =>
                      sl<FootballFeedBloc>()..add(const MatchFeedStartedEvent()),
                ),
                BlocProvider<VolleyballFeedBloc>(
                  create: (_) =>
                      sl<VolleyballFeedBloc>()..add(const MatchFeedStartedEvent()),
                ),
              ],
              child: HomeScreen(user: user),
            );
          },
          '/set-password': (_) => BlocProvider(
                create: (_) => sl<SetPasswordBloc>(),
                child: const SetNewPasswordScreen(),
              ),
          '/admin': (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => sl<LogoutBloc>(),
                  ),
                  BlocProvider<FootballFeedBloc>(
                    create: (_) =>
                        sl<FootballFeedBloc>()..add(const MatchFeedStartedEvent()),
                  ),
                  BlocProvider<VolleyballFeedBloc>(
                    create: (_) =>
                        sl<VolleyballFeedBloc>()..add(const MatchFeedStartedEvent()),
                  ),
                  BlocProvider<CreateMatchBloc>(
                    create: (_) => sl<CreateMatchBloc>(),
                  ),
                ],
                child: const AdminDashboardScreen(),
              ),
          '/superadmin': (_) => BlocProvider(
                create: (_) => sl<LogoutBloc>(),
                child: const AdminDashboardScreen(),
              ),
          '/create-match': (ctx) {
            final initialMatch =
                ModalRoute.of(ctx)?.settings.arguments as Match?;
            return BlocProvider<CreateMatchBloc>(
              create: (_) => sl<CreateMatchBloc>(),
              child: CreateMatchScreen(initialMatch: initialMatch),
            );
          },
          '/create-admin': (_) => BlocProvider<CreateAdminBloc>(
                create: (_) => sl<CreateAdminBloc>(),
                child: const CreateAdminScreen(),
              ),
          '/match-detail': (ctx) {
            final match = ModalRoute.of(ctx)!.settings.arguments as Match;
            return BlocProvider<MatchDetailBloc>(
              create: (_) => sl<MatchDetailBloc>(),
              child: MatchDetailScreen(match: match),
            );
          },
          '/volleyball-detail': (ctx) {
            final match = ModalRoute.of(ctx)!.settings.arguments as Match;
            return BlocProvider<VolleyballDetailBloc>(
              create: (_) => sl<VolleyballDetailBloc>(),
              child: VolleyballDetailScreen(match: match),
            );
          },
          '/live-mode': (ctx) {
            final match = ModalRoute.of(ctx)!.settings.arguments as Match;
            return BlocProvider<LiveModeBloc>(
              create: (_) => sl<LiveModeBloc>(),
              child: LiveModeScreen(match: match),
            );
          },
          '/volleyball-live-mode': (ctx) {
            final match = ModalRoute.of(ctx)!.settings.arguments as Match;
            return BlocProvider<VolleyballLiveModeBloc>(
              create: (_) => sl<VolleyballLiveModeBloc>(),
              child: VolleyballLiveModeScreen(match: match),
            );
          },
          '/profile': (ctx) {
            final userId = ctx.read<SessionCubit>().state!.id;
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => sl<LogoutBloc>(),
                ),
                BlocProvider(
                  create: (_) => ProfileBloc(
                    sl<UpdateProfileUseCase>(),
                    userId,
                  ),
                ),
                BlocProvider(
                  create: (_) => DeleteBloc(
                    sl<DeleteAccountUseCase>(),
                    userId,
                  ),
                ),
              ],
              child: const ProfileScreen(),
            );
          },
        },
        home: _SplashRouter(sessionFuture: _sessionFuture),
      ),
    );
  }
}

class _RoutingGate extends StatefulWidget {
  final AuthUser user;
  const _RoutingGate({required this.user});

  @override
  State<_RoutingGate> createState() => _RoutingGateState();
}

class _RoutingGateState extends State<_RoutingGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.user.role) {
        case 'SUPERADMIN':
          Navigator.pushReplacementNamed(context, '/superadmin');
        case 'ADMIN':
          Navigator.pushReplacementNamed(context, '/admin');
        default:
          Navigator.pushReplacementNamed(context, '/home',
              arguments: widget.user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );
  }
}

class _SplashRouter extends StatefulWidget {
  final Future<AuthUser?> sessionFuture;

  const _SplashRouter({required this.sessionFuture});

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final user = await widget.sessionFuture;
    if (!mounted) return;
    if (user != null) {
      context.read<SessionCubit>().setUser(user);
      Navigator.pushReplacementNamed(context, '/routing', arguments: user);
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }
}
