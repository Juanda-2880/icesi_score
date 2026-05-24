import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../match/domain/entities/match.dart';
import '../../../match/ui/bloc/match_feed_bloc.dart';
import '../../../match/ui/bloc/match_feed_event.dart';
import '../../../match/ui/bloc/match_feed_state.dart';
import '../../../session/session_cubit.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_top_bar.dart';
import '../../../../widgets/match/match_feed_list.dart';
import '../../../../widgets/match/sport_selector.dart';

class HomeScreen extends StatefulWidget {
  final AuthUser user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedSport = 0;
  String? _selectedStatus;

  void _onMatchTap(BuildContext context, Match match) {
    final footballBloc = context.read<FootballFeedBloc>();
    final volleyballBloc = context.read<VolleyballFeedBloc>();
    void reloadFeeds(_) {
      footballBloc.add(const MatchFeedStartedEvent());
      volleyballBloc.add(const MatchFeedStartedEvent());
    }

    if (match.sport == 'VOLLEYBALL') {
      Navigator.pushNamed(
        context,
        '/volleyball-detail',
        arguments: match,
      ).then(reloadFeeds);
      return;
    }
    final role = context.read<SessionCubit>().state?.role ?? '';
    final route = role == 'ADMIN' ? '/live-mode' : '/match-detail';
    Navigator.pushNamed(context, route, arguments: match).then(reloadFeeds);
  }

  Future<void> _refresh<B extends MatchFeedBloc>(BuildContext ctx) async {
    ctx.read<B>().add(const MatchFeedStartedEvent());
    await ctx.read<B>().stream.firstWhere((s) => s is! MatchFeedLoadingState);
  }

  void _onStatusFilterChanged(String? status) {
    setState(() => _selectedStatus = status);
    context.read<FootballFeedBloc>().add(
      MatchFeedStatusFilterChangedEvent(status),
    );
    context.read<VolleyballFeedBloc>().add(
      MatchFeedStatusFilterChangedEvent(status),
    );
  }

  Widget _buildStatusFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatusChip(label: 'Todos', status: null),
          _buildStatusChip(label: 'En vivo', status: 'IN_PROGRESS'),
          _buildStatusChip(label: 'Programados', status: 'SCHEDULED'),
          _buildStatusChip(label: 'Terminados', status: 'FINISHED'),
        ],
      ),
    );
  }

  Widget _buildStatusChip({required String label, required String? status}) {
    final selected = _selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppTheme.primaryColor,
        backgroundColor: AppTheme.surfaceColor,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.subtitleColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
        side: BorderSide.none,
        onSelected: (_) => _onStatusFilterChanged(status),
      ),
    );
  }

  Widget _buildFeedState<B extends MatchFeedBloc>(BuildContext context) {
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
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is MatchFeedLoadedState) {
          return MatchFeedList(
            matches: state.matches,
            onMatchTap: (m) => _onMatchTap(context, m),
            onRefresh: () => _refresh<B>(ctx),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTopBar(
              userName: widget.user.fullName,
              onProfileTap: () => Navigator.pushNamed(
                context,
                '/profile',
                arguments: widget.user,
              ),
              onSearchChanged: (query) {
                context.read<FootballFeedBloc>().add(
                  MatchFeedSearchChangedEvent(query),
                );
                context.read<VolleyballFeedBloc>().add(
                  MatchFeedSearchChangedEvent(query),
                );
              },
            ),
            SportSelector(
              selectedIndex: _selectedSport,
              onSelected: (i) => setState(() => _selectedSport = i),
            ),
            _buildStatusFilterChips(),
            Expanded(
              child: IndexedStack(
                index: _selectedSport,
                children: [
                  _buildFeedState<FootballFeedBloc>(context),
                  _buildFeedState<VolleyballFeedBloc>(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
