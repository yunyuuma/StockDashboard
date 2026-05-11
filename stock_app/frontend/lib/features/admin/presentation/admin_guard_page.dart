import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../stock/domain/app_session.dart';

class AdminGuardPage extends StatelessWidget {
  const AdminGuardPage({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isLoggedIn) {
      Future.microtask(() => context.go('/login'));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!AppSession.isAdmin) {
      Future.microtask(() => context.go('/companies'));
      return const Scaffold(
        body: Center(child: Text('管理者権限がありません。')),
      );
    }

    return child;
  }
}