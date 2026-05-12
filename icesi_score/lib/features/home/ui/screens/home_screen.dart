import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../match/domain/entities/match.dart';
import '../../../match/ui/bloc/match_feed_bloc.dart';
import '../../../match/ui/bloc/match_feed_event.dart';
import '../../../match/ui/bloc/match_feed_state.dart';
import '../../../session/session_cubit.dart';
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

  void _onMatchTap(BuildContext context, Match match) {
    if (match.sport == 'VOLLEYBALL') {
      Navigator.pushNamed(context, '/volleyball-detail', arguments: match);
      return;
    }
    final role = context.read<SessionCubit>().state?.role ?? '';
    final route = role == 'ADMIN' ? '/live-mode' : '/match-detail';
    Navigator.pushNamed(context, route, arguments: match);
  }

  Future<void> _refresh<B extends MatchFeedBloc>(BuildContext ctx) async {
    ctx.read<B>().add(const MatchFeedStartedEvent());
    await ctx.read<B>().stream.firstWhere((s) => s is! MatchFeedLoadingState);
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
            ),
            SportSelector(
              selectedIndex: _selectedSport,
              onSelected: (i) => setState(() => _selectedSport = i),
            ),
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
