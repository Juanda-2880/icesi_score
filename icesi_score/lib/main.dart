import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide AuthUser;
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' hide AuthUser;
import 'amplifyconfiguration.dart' show amplifyconfig;
import 'theme/app_theme.dart';
import 'features/auth/data/repository/auth_repository_impl.dart';
import 'features/auth/data/source/cognito_auth_data_source.dart';
import 'features/auth/domain/entities/auth_user.dart';
import 'features/auth/domain/usecases/get_stored_session_usecase.dart';
import 'features/login/ui/screens/welcome_screen.dart';
import 'features/login/ui/screens/login_screen.dart';
import 'features/register/ui/screens/register_screen.dart';
import 'features/verify/ui/screens/verify_screen.dart';
import 'features/home/ui/screens/home_screen.dart';
import 'features/admin/ui/screens/admin_dashboard_screen.dart';
import 'features/auth/domain/usecases/delete_account_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/domain/usecases/update_profile_usecase.dart';
import 'features/profile/ui/bloc/delete_bloc.dart';
import 'features/profile/ui/bloc/logout_bloc.dart';
import 'features/profile/ui/bloc/profile_bloc.dart';
import 'features/profile/ui/screens/profile_screen.dart';
import 'features/session/session_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return GetStoredSessionUseCase(
      AuthRepositoryImpl(CognitoAuthDataSource()),
    )();
  }

  Widget _resolveHome(AuthUser user) {
    if (user.role == 'ADMIN' || user.role == 'SUPERADMIN') {
      return AdminDashboardScreen(user: user);
    }
    return HomeScreen(user: user);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionCubit>(
      create: (_) => SessionCubit(),
      child: MaterialApp(
        title: 'IcesiScore',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routes: {
          '/welcome':  (_) => const WelcomeScreen(),
          '/login':    (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/verify':   (_) => const VerifyScreen(),
          '/routing': (ctx) {
            final user = ModalRoute.of(ctx)!.settings.arguments as AuthUser;
            return _resolveHome(user);
          },
          '/home': (ctx) {
            final user = ModalRoute.of(ctx)!.settings.arguments as AuthUser;
            return HomeScreen(user: user);
          },
          '/admin': (ctx) {
            final user = ModalRoute.of(ctx)!.settings.arguments as AuthUser;
            return AdminDashboardScreen(user: user);
          },
          '/profile': (ctx) {
            final userId = ctx.read<SessionCubit>().state!.id;
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => LogoutBloc(
                    SignOutUseCase(AuthRepositoryImpl(CognitoAuthDataSource())),
                  ),
                ),
                BlocProvider(
                  create: (_) => ProfileBloc(
                    UpdateProfileUseCase(
                      AuthRepositoryImpl(CognitoAuthDataSource()),
                    ),
                    userId,
                  ),
                ),
                BlocProvider(
                  create: (_) => DeleteBloc(
                    DeleteAccountUseCase(
                      AuthRepositoryImpl(CognitoAuthDataSource()),
                    ),
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
