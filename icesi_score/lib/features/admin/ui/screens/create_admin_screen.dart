import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/repository/auth_repository_impl.dart';
import '../../../auth/data/source/cognito_auth_data_source.dart';
import '../../../auth/domain/usecases/create_admin_usecase.dart';
import '../../../session/session_cubit.dart';
import '../../../../widgets/common/labeled_text_field.dart';
import '../../../../widgets/common/loading_button.dart';
import '../bloc/create_admin_bloc.dart';
import '../bloc/create_admin_event.dart';
import '../bloc/create_admin_state.dart';

class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<SessionCubit>().state?.role != 'SUPERADMIN') {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<CreateAdminBloc>().add(CreateAdminSubmittedEvent(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      university: _universityController.text.trim(),
    ));
  }

  void _showError(BuildContext ctx, String message) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName es obligatorio.';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es obligatorio.';
    final emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Ingresa un correo válido.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateAdminBloc>(
      create: (_) => CreateAdminBloc(
        CreateAdminUseCase(AuthRepositoryImpl(CognitoAuthDataSource())),
      ),
      child: BlocListener<CreateAdminBloc, CreateAdminState>(
        listener: (ctx, state) {
          if (state is CreateAdminSuccessState) {
            _formKey.currentState?.reset();
            for (final c in [_fullNameController, _emailController, _phoneController, _universityController]) {
              c.clear();
            }
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Invitación enviada al nuevo Administrador ✓'),
              ),
            );
          } else if (state is CreateAdminFailureState) {
            _showError(ctx, state.errorMessage);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Nuevo Administrador'),
            leading: const BackButton(),
          ),
          body: BlocBuilder<CreateAdminBloc, CreateAdminState>(
            builder: (ctx, state) {
              final isLoading = state is CreateAdminLoadingState;
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledTextField(
                        label: 'Nombre Completo',
                        controller: _fullNameController,
                        hint: 'Nombre y apellido',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) => _validateRequired(v, 'El nombre'),
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Email',
                        controller: _emailController,
                        hint: 'admin@uicesi.edu.co',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Teléfono',
                        controller: _phoneController,
                        hint: '+573001234567',
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        validator: (v) => _validateRequired(v, 'El teléfono'),
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Universidad',
                        controller: _universityController,
                        hint: 'ICESI',
                        prefixIcon: const Icon(Icons.school_outlined),
                        validator: (v) => _validateRequired(v, 'La universidad'),
                      ),
                      const SizedBox(height: 40),
                      LoadingButton(
                        isLoading: isLoading,
                        onPressed: isLoading ? () {} : () => _submit(ctx),
                        label: 'Enviar Invitación',
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
