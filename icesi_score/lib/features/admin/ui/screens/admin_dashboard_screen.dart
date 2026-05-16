import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../match/domain/entities/match.dart';
import '../../../match/ui/bloc/create_match_bloc.dart';
import '../../../match/ui/bloc/create_match_event.dart';
import '../../../match/ui/bloc/create_match_state.dart';
import '../../../match/ui/bloc/match_feed_bloc.dart';
import '../../../match/ui/bloc/match_feed_event.dart';
import '../../../match/ui/bloc/match_feed_state.dart';
import '../../../profile/ui/bloc/logout_bloc.dart';
import '../../../profile/ui/bloc/logout_event.dart';
import '../../../profile/ui/bloc/logout_state.dart';
import '../../../session/session_cubit.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/match/match_feed_list.dart';
import '../../../../widgets/match/sport_selector.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoadingDialogOpen = false;

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

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionCubit>().state;
    final isSuperAdmin = user?.role == 'SUPERADMIN';

    return BlocListener<LogoutBloc, LogoutState>(
      listener: _onLogoutState,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isSuperAdmin ? 'Panel Superadministrador' : 'Panel Administrador',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Mi perfil',
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => context
                  .read<LogoutBloc>()
                  .add(const LogoutRequestedEvent()),
            ),
          ],
        ),
        body: isSuperAdmin ? _SuperAdminBody() : const _AdminBody(),
        floatingActionButton: isSuperAdmin
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  final footballBloc = context.read<FootballFeedBloc>();
                  final volleyballBloc = context.read<VolleyballFeedBloc>();
                  await Navigator.pushNamed(context, '/create-match');
                  if (!mounted) return;
                  footballBloc.add(const MatchFeedStartedEvent());
                  volleyballBloc.add(const MatchFeedStartedEvent());
                },
                backgroundColor: AppTheme.appBlue,
                tooltip: 'Nuevo partido',
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}

class _SuperAdminBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 64, color: AppTheme.appBlue),
            const SizedBox(height: 16),
            const Text(
              'Gestión de Administradores',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Nuevo Administrador'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.appBlue,
                minimumSize: const Size(double.infinity, 0),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.pushNamed(context, '/create-admin'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBody extends StatefulWidget {
  const _AdminBody();

  @override
  State<_AdminBody> createState() => _AdminBodyState();
}

class _AdminBodyState extends State<_AdminBody> {
  int _selectedSport = 0;

  void _reloadFeeds() {
    context.read<FootballFeedBloc>().add(const MatchFeedStartedEvent());
    context.read<VolleyballFeedBloc>().add(const MatchFeedStartedEvent());
  }

  void _onMatchTap(Match match) {
    final footballBloc = context.read<FootballFeedBloc>();
    final volleyballBloc = context.read<VolleyballFeedBloc>();
    final route =
        match.sport == 'VOLLEYBALL' ? '/volleyball-detail' : '/live-mode';
    Navigator.pushNamed(context, route, arguments: match).then((_) {
      footballBloc.add(const MatchFeedStartedEvent());
      volleyballBloc.add(const MatchFeedStartedEvent());
    });
  }

  void _onEditTap(Match match) async {
    final footballBloc = context.read<FootballFeedBloc>();
    final volleyballBloc = context.read<VolleyballFeedBloc>();
    await Navigator.pushNamed(context, '/create-match', arguments: match);
    if (!mounted) return;
    footballBloc.add(const MatchFeedStartedEvent());
    volleyballBloc.add(const MatchFeedStartedEvent());
  }

  void _onDeleteTap(Match match) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar partido'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este partido? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context
                  .read<CreateMatchBloc>()
                  .add(DeleteMatchRequestedEvent(match.id));
            },
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Color(0xFFFF4444)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh<B extends MatchFeedBloc>(BuildContext ctx) async {
    ctx.read<B>().add(const MatchFeedStartedEvent());
    await ctx.read<B>().stream.firstWhere((s) => s is! MatchFeedLoadingState);
  }

  Widget _buildFeedState<B extends MatchFeedBloc>() {
    return BlocBuilder<B, MatchFeedState>(
      builder: (ctx, state) {
        if (state is MatchFeedLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is MatchFeedErrorState) {
          return RefreshIndicator(
            onRefresh: () => _refresh<B>(ctx),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Center(
                    child: Text(state.message,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is MatchFeedLoadedState) {
          return MatchFeedList(
            matches: state.matches,
            onMatchTap: _onMatchTap,
            onRefresh: () => _refresh<B>(ctx),
            isAdmin: true,
            onEditTap: _onEditTap,
            onDeleteTap: _onDeleteTap,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateMatchBloc, CreateMatchState>(
      listener: (ctx, state) {
        if (state is DeleteMatchSuccessState) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Partido eliminado')),
          );
          _reloadFeeds();
        } else if (state is CreateMatchFailureState) {
          showDialog<void>(
            context: ctx,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: Text(state.message),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SportSelector(
            selectedIndex: _selectedSport,
            onSelected: (i) => setState(() => _selectedSport = i),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedSport,
              children: [
                _buildFeedState<FootballFeedBloc>(),
                _buildFeedState<VolleyballFeedBloc>(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
