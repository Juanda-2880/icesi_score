import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/repository/auth_repository_impl.dart';
import '../../../auth/data/source/cognito_auth_data_source.dart';
import '../../../auth/domain/usecases/sign_up_usecase.dart';
import '../../../../widgets/common/labeled_text_field.dart';
import '../../../../widgets/common/loading_button.dart';
import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';
import '../bloc/register_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterBloc _bloc;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = RegisterBloc(
      SignUpUseCase(AuthRepositoryImpl(CognitoAuthDataSource())),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _bloc.add(RegisterSubmittedEvent(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      university: _universityController.text.trim(),
    ));
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error al registrarse'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es obligatorio.';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Ingresa un correo válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    if (value.length < 8) return 'Mínimo 8 caracteres.';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Debe incluir al menos una mayúscula.';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Debe incluir al menos un número.';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName es obligatorio.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccessState) {
            Navigator.pushReplacementNamed(
              context,
              '/verify',
              arguments: _emailController.text.trim(),
            );
          } else if (state is RegisterFailureState) {
            _showError(state.errorMessage);
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Create Account')),
          body: BlocBuilder<RegisterBloc, RegisterState>(
            builder: (context, state) {
              final isLoading = state is RegisterLoadingState;
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        hint: 'Your full name',
                        validator: (v) => _validateRequired(v, 'El nombre'),
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Email',
                        controller: _emailController,
                        hint: 'your.email@uicesi.edu.co',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Phone',
                        controller: _phoneController,
                        hint: '+573001234567',
                        keyboardType: TextInputType.phone,
                        validator: (v) => _validateRequired(v, 'El teléfono'),
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'University',
                        controller: _universityController,
                        hint: 'ICESI',
                        validator: (v) => _validateRequired(v, 'La universidad'),
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Password',
                        controller: _passwordController,
                        hint: '••••••••',
                        obscureText: true,
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        hint: '••••••••',
                        obscureText: true,
                        validator: _validateConfirm,
                      ),
                      const SizedBox(height: 40),
                      LoadingButton(
                        isLoading: isLoading,
                        onPressed: isLoading ? () {} : _submit,
                        label: 'Create Account',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
