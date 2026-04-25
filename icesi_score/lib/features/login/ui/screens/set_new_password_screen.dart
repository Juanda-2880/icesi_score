import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../session/session_cubit.dart';
import '../bloc/set_password_bloc.dart';
import '../bloc/set_password_event.dart';
import '../bloc/set_password_state.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const _bgColor = Color(0xFF121212);
  static const _blue = Color(0xFF4343D8);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context
        .read<SetPasswordBloc>()
        .add(SetPasswordSubmittedEvent(_passwordController.text));
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    if (value.length < 8) return 'Mínimo 8 caracteres.';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Debe incluir al menos una mayúscula.';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Debe incluir al menos una minúscula.';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Debe incluir al menos un número.';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SetPasswordBloc, SetPasswordState>(
      listener: (context, state) {
        if (state is SetPasswordSuccessState) {
          context.read<SessionCubit>().setUser(state.user);
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/routing',
            (_) => false,
            arguments: state.user,
          );
        } else if (state is SetPasswordFailureState) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error'),
              content: Text(state.errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          title: const Text(
            'Establece tu contraseña',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<SetPasswordBloc, SetPasswordState>(
          builder: (context, state) {
            final isLoading = state is SetPasswordLoadingState;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Icon(
                      Icons.lock_reset,
                      color: Color(0xFF4343D8),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tu cuenta fue creada por un administrador.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Crea una contraseña segura para continuar.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    _PasswordField(
                      label: 'Nueva contraseña',
                      controller: _passwordController,
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    _PasswordField(
                      label: 'Confirmar contraseña',
                      controller: _confirmController,
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: _validateConfirm,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mínimo 8 caracteres · mayúscula · minúscula · número',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Establecer contraseña',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
