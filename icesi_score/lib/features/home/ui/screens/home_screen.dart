import 'package:flutter/material.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../../widgets/common/app_top_bar.dart';

class HomeScreen extends StatefulWidget {
  final AuthUser user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              userName: widget.user.fullName,
              onProfileTap: () => Navigator.pushNamed(
                context,
                '/profile',
                arguments: widget.user,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Próximamente...',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
