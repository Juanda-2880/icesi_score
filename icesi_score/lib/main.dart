import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'amplifyconfiguration.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';

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
    _configureAmplifyAndCheckAuth();
  }

  Future<void> _configureAmplifyAndCheckAuth() async {
    try {
      // 1. Configurar Amplify
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);
      await Amplify.configure(amplifyconfig);
      print('✅ Amplify configurado correctamente');

      // 2. Revisar si el usuario ya tiene sesión iniciada en el celular
      final session = await Amplify.Auth.fetchAuthSession();

      if (session.isSignedIn) {
        // Extraer el token y los roles para saber a dónde mandarlo
        final cognitoSession = session as CognitoAuthSession;
        final jwtToken =
            cognitoSession.userPoolTokensResult.value.accessToken.raw;

        Map<String, dynamic> decodedToken = JwtDecoder.decode(jwtToken);
        List<dynamic> groups = decodedToken['cognito:groups'] ?? [];

        if (groups.contains('Admins')) {
          _initialScreen = AdminDashboardScreen(token: jwtToken);
        } else {
          _initialScreen = HomeScreen(token: jwtToken);
        }
      } else {
        // Si no hay sesión guardada, mostramos la pantalla de bienvenida normal
        _initialScreen = const WelcomeScreen();
      }
    } catch (e) {
      print('❌ Error inicializando la app: $e');
      // Por seguridad, si hay error lo mandamos al inicio
      _initialScreen = const WelcomeScreen();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Quitamos la pantalla de carga
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IcesiScore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Si está cargando muestra el circulo, si no, muestra la pantalla decidida
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF5C5CFF)),
              ),
            )
          : _initialScreen,
    );
  }
}
