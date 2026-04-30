import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../session/session_cubit.dart';
import '../bloc/delete_bloc.dart';
import '../bloc/delete_event.dart';
import '../bloc/delete_state.dart';
import '../bloc/logout_bloc.dart';
import '../bloc/logout_event.dart';
import '../bloc/logout_state.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AuthUser _user;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _universityController;

  bool _isLoadingDialogOpen = false;
  bool _isDeleteDialogOpen  = false;

  static const Color _blue    = Color(0xFF4343D8);
  static const Color _orange  = Color(0xFFF1A25D);
  static const Color _red     = Color(0xFFFF4444);
  static const Color _bgColor = Color(0xFF121212);

  static String _displayRole(String role) => switch (role) {
        'NORMAL'     => 'AFICIONADO',
        'ADMIN'      => 'ADMINISTRADOR',
        'SUPERADMIN' => 'SUPER ADMIN',
        _            => role,
      };

  @override
  void initState() {
    super.initState();
    _user = context.read<SessionCubit>().state!;
    _nameController       = TextEditingController(text: _user.fullName);
    _emailController      = TextEditingController(text: _user.email);
    _phoneController      = TextEditingController(text: _user.phone ?? '');
    _universityController = TextEditingController(text: _user.university ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  void _onProfileState(BuildContext context, ProfileState state) {
    if (state is ProfileSavedState) {
      setState(() => _user = state.user);
      context.read<SessionCubit>().setUser(state.user);
      _nameController.text       = state.user.fullName;
      _phoneController.text      = state.user.phone ?? '';
      _universityController.text = state.user.university ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Perfil actualizado',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: _blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (state is ProfileSaveFailureState) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error al guardar'),
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
  }

  void _onLogoutState(BuildContext context, LogoutState state) {
    if (state is LogoutLoadingState && !_isLoadingDialogOpen) {
      _isLoadingDialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ).whenComplete(() => _isLoadingDialogOpen = false);
    } else if (state is LogoutSuccessState) {
      if (_isLoadingDialogOpen) {
        Navigator.of(context).pop();
        _isLoadingDialogOpen = false;
      }
      context.read<SessionCubit>().clearUser();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } else if (state is LogoutFailureState) {
      if (_isLoadingDialogOpen) {
        Navigator.of(context).pop();
        _isLoadingDialogOpen = false;
      }
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error al cerrar sesión'),
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
  }

  void _onDeleteState(BuildContext context, DeleteState state) {
    if (state is DeletingState && !_isDeleteDialogOpen) {
      _isDeleteDialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ).whenComplete(() => _isDeleteDialogOpen = false);
    } else if (state is DeleteSuccessState) {
      if (_isDeleteDialogOpen) {
        Navigator.of(context).pop();
        _isDeleteDialogOpen = false;
      }
      context.read<SessionCubit>().clearUser();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cuenta eliminada.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (state is DeleteFailureState) {
      if (_isDeleteDialogOpen) {
        Navigator.of(context).pop();
        _isDeleteDialogOpen = false;
      }
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error al eliminar'),
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
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LogoutBloc, LogoutState>(listener: _onLogoutState),
        BlocListener<ProfileBloc, ProfileState>(listener: _onProfileState),
        BlocListener<DeleteBloc, DeleteState>(listener: _onDeleteState),
      ],
      child: Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _bgColor,
            elevation: 0,
            leading: const BackButton(color: Colors.white),
            title: const Text(
              'My Profile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeaderCard(),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Personal Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileField(
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  controller: _nameController,
                ),
                _ProfileField(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  readOnly: true,
                ),
                _ProfileField(
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                ),
                _ProfileField(
                  label: 'University',
                  icon: Icons.school_outlined,
                  controller: _universityController,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (ctx, state) {
                      final isSaving = state is ProfileSavingState;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () {
                                final newName  = _nameController.text.trim();
                                final newPhone = _phoneController.text.trim();
                                final newUniv  = _universityController.text.trim();
                                final hasChanges =
                                    newName  != _user.fullName ||
                                    newPhone != (_user.phone ?? '') ||
                                    newUniv  != (_user.university ?? '');
                                if (!hasChanges) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'No hay cambios para guardar',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: Colors.white12),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                ctx.read<ProfileBloc>().add(
                                  ProfileSaveRequestedEvent(
                                    fullName:   newName,
                                    phone:      newPhone,
                                    university: newUniv,
                                  ),
                                );
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Danger Zone',
                    style: TextStyle(
                      color: _red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDangerZone(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4343D8), Color(0xFF0D0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: _orange,
            child: Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.school, color: _orange, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _user.university ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: _orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _displayRole(_user.role),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: _red.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Delete Account',
              style: TextStyle(color: _red),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: _red, size: 16),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  '¿Eliminar cuenta?',
                  style: TextStyle(
                    color: _red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'Esta acción es permanente y no se puede deshacer.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.read<DeleteBloc>().add(
                            const DeleteAccountRequestedEvent(),
                          );
                    },
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(
                        color: _red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: _red.withValues(alpha: 0.3), height: 1),
          TextButton.icon(
            onPressed: () =>
                context.read<LogoutBloc>().add(const LogoutRequestedEvent()),
            icon: const Icon(Icons.logout, color: _red),
            label: const Text('Log Out', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool readOnly;

  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey, size: 13),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
