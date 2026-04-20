import 'package:flutter/material.dart';
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

  Widget _buildSplash() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _resolveHome(AuthUser? user) {
    if (user == null) return const WelcomeScreen();
    if (user.role == 'ADMIN' || user.role == 'SUPERADMIN') {
      return AdminDashboardScreen(user: user);
    }
    return HomeScreen(user: user);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IcesiScore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routes: {
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
      },
      home: FutureBuilder<AuthUser?>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildSplash();
          }
          return _resolveHome(snapshot.data);
        },
      ),
    );
  }
}
