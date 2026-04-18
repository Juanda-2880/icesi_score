import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';
import 'theme/app_theme.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/super_admin_screen.dart';

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
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);
      await Amplify.configure(amplifyconfig);

      final AppUser? user = await AuthService.checkExistingSession();

      if (user != null) {
        if (user.role == UserRole.superAdmin) {
          _initialScreen = const SuperAdminScreen();
        } else if (user.role == UserRole.admin) {
          _initialScreen = AdminDashboardScreen(token: user.token);
        } else {
          _initialScreen = HomeScreen(token: user.token);
        }
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
