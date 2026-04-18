import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';
import 'theme/app_theme.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'features/login/ui/screens/welcome_screen.dart';
import 'features/login/ui/screens/login_screen.dart';
import 'features/register/ui/screens/register_screen.dart';
import 'features/verify/ui/screens/verify_screen.dart';
import 'features/home/ui/screens/home_screen.dart';
import 'features/admin/ui/screens/admin_dashboard_screen.dart';

void main() {
  runApp(const IcesiScoreApp());
}

class IcesiScoreApp extends StatefulWidget {
  const IcesiScoreApp({super.key});

  @override
  State<IcesiScoreApp> createState() => _IcesiScoreAppState();
}

class _IcesiScoreAppState extends State<IcesiScoreApp> {
  bool _isLoading = true;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Amplify.addPlugin(AmplifyAuthCognito());
      await Amplify.configure(amplifyconfig);

      final AppUser? user = await AuthService.checkExistingSession();

      if (user != null) {
        _initialScreen = user.role == UserRole.admin
            ? AdminDashboardScreen(token: user.token)
            : HomeScreen(token: user.token);
      } else {
        _initialScreen = const WelcomeScreen();
      }
    } catch (e) {
      _initialScreen = const WelcomeScreen();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IcesiScore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Rutas nombradas usadas por register → verify → login
      routes: {
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/verify':   (_) => const VerifyScreen(),
      },
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            )
          : _initialScreen,
    );
  }
}
