import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';

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
  AuthUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _configureAmplify();
    _checkAuthStatus();
  }

  Future<void> _configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);
      await Amplify.configure(amplifyconfig);
      setState(() {
        _amplifyConfigured = true;
      });
      debugPrint('✅ Amplify configurado correctamente');
    } catch (e) {
      debugPrint('❌ Error configurando Amplify: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      debugPrint('No hay usuario autenticado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Icesi Score - Login',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: _amplifyConfigured
          ? (_currentUser != null ? const HomeScreen() : const AuthScreen())
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

// ===================== PANTALLA DE AUTENTICACIÓN =====================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true; // true = login, false = signup
  bool _isSignUpComplete = false;
  bool _isLoading = false;
  String? _selectedRole; // "admin" o "spectator"
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ===================== VALIDACIONES =====================
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener mayúsculas';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener números';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Debe contener minúsculas';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'El código es requerido';
    }
    if (value.length != 6) {
      return 'El código debe tener 6 dígitos';
    }
    return null;
  }

  // ===================== FUNCIONES DE AUTENTICACIÓN =====================

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      _showError('Selecciona un rol (Administrador o Espectador)');
      return;
    }

    setState(() => _isLoading = true);
    _clearMessages();

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

      // TODO: Guardar el rol en Firebase, DynamoDB o base de datos
      // Por ahora se puede guardar localmente o en una tabla separada
      debugPrint('Rol seleccionado: $_selectedRole');

      setState(() {
        _isSignUpComplete = result.nextStep.signUpStep == 'CONFIRM_SIGN_UP';
        _successMessage =
            '✅ Registro exitoso.\nVerifica tu correo para el código de confirmación.';
      });
    } on AuthException catch (e) {
      _showError('Error en registro: ${e.message}');
    } catch (e) {
      _showError('Error inesperado: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _clearMessages();

    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: _emailController.text.trim(),
        confirmationCode: _codeController.text.trim(),
      );

      if (result.isSignUpComplete) {
        setState(() {
          _isSignUpComplete = false;
          _isLogin = true;
          _successMessage =
              '✅ Cuenta verificada.\nAhora inicia sesión con tus credenciales.';
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _codeController.clear();
        });
      }
    } on AuthException catch (e) {
      _showError('Error confirmando código: ${e.message}');
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _clearMessages();

    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();
        setState(() {
          _successMessage = '✅ ¡Inicio de sesión exitoso!';
        });

        // Navegar al HomeScreen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } on AuthException catch (e) {
      _showError('Error en login: ${e.message}');
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===================== FUNCIONES AUXILIARES =====================

  void _clearMessages() {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = '';
    });
  }

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
      _isSignUpComplete = false;
      _clearMessages();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _codeController.clear();
      _selectedRole = null;
    });
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icesi Score'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Título
                const SizedBox(height: 20),
                const Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                Text(
                  _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 30),

                // MENSAJE DE ERROR
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // MENSAJE DE ÉXITO
                if (_successMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _successMessage,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // ============== FORMULARIO LOGIN ==============
                if (_isLogin && !_isSignUpComplete) ...[
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo Institucional',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 24),

                  // Botón Iniciar Sesión
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signIn,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoading ? 'Cargando...' : 'Iniciar Sesión'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cambiar a Registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      TextButton(
                        onPressed: _switchMode,
                        child: const Text(
                          'Regístrate aquí',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
                // ============== FORMULARIO REGISTRO ==============
                else if (!_isLogin && !_isSignUpComplete) ...[
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo Institucional',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      helperText:
                          'Mín 8 caracteres, mayúsculas, minúsculas y números',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // Confirmar Contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    obscureText: true,
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 20),

                  // Seleccionar Rol
                  const Text(
                    'Selecciona tu rol:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Botón Administrador
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedRole = 'admin');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'admin'
                                  ? Colors.deepPurple
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == 'admin'
                                    ? Colors.deepPurple
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  color: _selectedRole == 'admin'
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Administrador',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedRole == 'admin'
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Botón Espectador
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedRole = 'spectator');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'spectator'
                                  ? Colors.deepPurple
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == 'spectator'
                                    ? Colors.deepPurple
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  color: _selectedRole == 'spectator'
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Espectador',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedRole == 'spectator'
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón Registrarse
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signUp,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add),
                    label: Text(_isLoading ? 'Cargando...' : 'Registrarse'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cambiar a Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Ya tienes cuenta?'),
                      TextButton(
                        onPressed: _switchMode,
                        child: const Text(
                          'Inicia sesión',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
                // ============== VERIFICACIÓN DE CÓDIGO ==============
                else if (_isSignUpComplete) ...[
                  const Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ingresa el código enviado a:\n${_emailController.text}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Campo Código
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Código de Verificación',
                      prefixIcon: const Icon(Icons.security),
                      hintText: '000000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, letterSpacing: 4),
                    validator: _validateCode,
                  ),
                  const SizedBox(height: 24),

                  // Botón Confirmar
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _confirmSignUp,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      _isLoading ? 'Verificando...' : 'Verificar Código',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _switchMode,
                      child: const Text('Volver'),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== PANTALLA PRINCIPAL (HOME) =====================
// NOTA IMPORTANTE: El rol se debe almacenar en:
// 1. SharedPreferences (local en el dispositivo)
// 2. Firebase Realtime Database
// 3. DynamoDB con Lambda
// Por ahora se guarda en memoria, implementa tu preferencia

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthUser? _currentUser;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      debugPrint('Usuario: ${user.userId}');
      debugPrint('Nombre usuario: ${user.username}');
    } catch (e) {
      debugPrint('Error cargando datos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      debugPrint('Error cerrando sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icesi Score'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de Bienvenida
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¡Bienvenido!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentUser?.username ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Imagen Principal
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sports_soccer,
                            size: 80,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ICESI SCORE',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sistema de Gestión de Eventos Deportivos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Opciones según Rol
                    const Text(
                      'Opciones Disponibles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid de opciones
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildOptionCard(
                          icon: Icons.event,
                          title: 'Eventos',
                          color: Colors.blue,
                          onTap: () {
                            debugPrint('Navegar a Eventos');
                          },
                        ),
                        _buildOptionCard(
                          icon: Icons.leaderboard,
                          title: 'Clasificación',
                          color: Colors.orange,
                          onTap: () {
                            debugPrint('Navegar a Clasificación');
                          },
                        ),
                        _buildOptionCard(
                          icon: Icons.person,
                          title: 'Mi Perfil',
                          color: Colors.green,
                          onTap: () {
                            debugPrint('Navegar a Perfil');
                          },
                        ),
                        _buildOptionCard(
                          icon: Icons.settings,
                          title: 'Configuración',
                          color: Colors.red,
                          onTap: () {
                            debugPrint('Navegar a Configuración');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Información del usuario
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de la Sesión',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _infoRow('Usuario:', _currentUser?.username ?? 'N/A'),
                          const SizedBox(height: 8),
                          _infoRow(
                            'Email:',
                            _currentUser?.userId.split('|').last ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ===================== EXTENSIÓN PARA RUTAS =====================
extension on NavigatorState {
  void pushReplacementNamed(String routeName) {
    pushNamedAndRemoveUntil(routeName, (route) => false);
  }
}
