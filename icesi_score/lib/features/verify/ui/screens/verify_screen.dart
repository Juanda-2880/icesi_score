import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/repository/auth_repository_impl.dart';
import '../../../auth/data/source/cognito_auth_data_source.dart';
import '../../../auth/domain/usecases/confirm_sign_up_usecase.dart';
import '../../../../widgets/common/loading_button.dart';
import '../bloc/verify_bloc.dart';
import '../bloc/verify_event.dart';
import '../bloc/verify_state.dart';

class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return BlocProvider(
      create: (_) => VerifyBloc(
        ConfirmSignUpUseCase(
          AuthRepositoryImpl(CognitoAuthDataSource()),
        ),
      ),
      child: _VerifyView(email: email),
    );
  }
}

class _VerifyView extends StatefulWidget {
  final String email;

  const _VerifyView({required this.email});

  @override
  State<_VerifyView> createState() => _VerifyViewState();
}

class _VerifyViewState extends State<_VerifyView> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showError('El código debe tener exactamente 6 dígitos.');
      return;
    }
    context.read<VerifyBloc>().add(
          VerifyCodeSubmittedEvent(email: widget.email, code: code),
        );
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error de verificación'),
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerifyBloc, VerifyState>(
      listener: (context, state) {
        if (state is VerifySuccessState) {
          Navigator.pushReplacementNamed(context, '/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta verificada con éxito! Ya puedes iniciar sesión.'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is VerifyFailureState) {
          _showError(state.errorMessage);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Verify Identity')),
        body: BlocBuilder<VerifyBloc, VerifyState>(
          builder: (context, state) {
            final isLoading = state is VerifyLoadingState;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We sent a 6-digit code to ${widget.email}',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: 'Enter 6-digit code',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 40),
                  LoadingButton(
                    isLoading: isLoading,
                    onPressed: isLoading ? () {} : _submit,
                    label: 'Verify and Enter App',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
