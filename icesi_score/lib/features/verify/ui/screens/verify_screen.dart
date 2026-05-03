import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../widgets/common/loading_button.dart';
import '../bloc/verify_bloc.dart';
import '../bloc/verify_event.dart';
import '../bloc/verify_state.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  late final String _email;
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
  }

  @override
  void dispose() {
    for (final c in _digitControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _submit() {
    final code = _digitControllers.map((c) => c.text).join();
    if (code.length != 6) {
      _showError('El código debe tener exactamente 6 dígitos.');
      return;
    }
    context.read<VerifyBloc>().add(VerifyCodeSubmittedEvent(email: _email, code: code));
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
                    'We sent a 6-digit code to $_email',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => SizedBox(
                      width: 44,
                      child: TextField(
                        controller: _digitControllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 1 && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          } else if (value.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    )),
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
