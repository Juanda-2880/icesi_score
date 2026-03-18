import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart'; // Tu archivo de configuración

void main() {
  runApp(const SofaScoreApp());
}

class SofaScoreApp extends StatefulWidget {
  const SofaScoreApp({super.key});

  @override
  State<SofaScoreApp> createState() => _SofaScoreAppState();
}

class _SofaScoreAppState extends State<SofaScoreApp> {
  bool _amplifyConfigured = false;

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);
      await Amplify.configure(amplifyconfig);
      setState(() {
        _amplifyConfigured = true;
      });
      print('✅ Amplify configurado correctamente');
    } catch (e) {
      print('❌ Error configurando Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Icesi Score Auth',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: Scaffold(
        appBar: AppBar(title: const Text('Prototipo Login Cognito')),
        body: _amplifyConfigured
            ? const AuthWidget()
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class AuthWidget extends StatefulWidget {
  const AuthWidget({super.key});

  @override
  State<AuthWidget> createState() => _AuthWidgetState();
}

class _AuthWidgetState extends State<AuthWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isSignUpComplete = false;
  String _message = '';

  // 1. Registrar Usuario (ACTUALIZADO CON USER ATTRIBUTES)
  Future<void> _signUp() async {
    try {
      final result = await Amplify.Auth.signUp(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: _emailController.text.trim(),
          },
        ),
      );
      setState(() {
        _isSignUpComplete = result.nextStep.signUpStep == 'CONFIRM_SIGN_UP';
        _message = 'Registro exitoso. Revisa tu correo para el código.';
      });
    } catch (e) {
      setState(() => _message = 'Error en registro: $e');
    }
  }

  // 2. Confirmar Código de Correo
  Future<void> _confirmSignUp() async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: _emailController.text.trim(),
        confirmationCode: _codeController.text.trim(),
      );
      if (result.isSignUpComplete) {
        setState(() {
          _isSignUpComplete = false; // Volver a la vista de login
          _message = 'Cuenta verificada. ¡Ya puedes iniciar sesión!';
        });
      }
    } catch (e) {
      setState(() => _message = 'Error confirmando: $e');
    }
  }

  // 3. Iniciar Sesión (Login)
  Future<void> _signIn() async {
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (result.isSignedIn) {
        // AQUÍ OBTENEMOS EL TOKEN JWT PARA EL API GATEWAY
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        final jwtToken = session.userPoolTokensResult.value.accessToken.raw;

        setState(
          () => _message =
              '¡Login Exitoso! \nRevisa la consola para ver tu Token.',
        );
        print('=========================================');
        print('✅ TOKEN JWT OBTENIDO CON ÉXITO:');
        print(jwtToken);
        print('=========================================');
      }
    } catch (e) {
      setState(() => _message = 'Error en login: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo Institucional',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
          ),
          const SizedBox(height: 20),

          if (!_isSignUpComplete) ...[
            ElevatedButton(
              onPressed: _signUp,
              child: const Text('Registrarse'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _signIn,
              child: const Text('Iniciar Sesión'),
            ),
          ] else ...[
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código de Verificación',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _confirmSignUp,
              child: const Text('Confirmar Código'),
            ),
          ],

          const SizedBox(height: 20),
          Text(
            _message,
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
