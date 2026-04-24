import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/stock/domain/app_session.dart';
import 'features/stock/presentation/login_page.dart';
import 'features/stock/presentation/register_page.dart';
import 'features/stock/presentation/company_register_page.dart';
import 'features/stock/presentation/company_search_page.dart';
import 'features/stock/presentation/stock_detail_page.dart';
import 'features/admin/presentation/admin_company_profile_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSession.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: AppSession.isLoggedIn
        ? (AppSession.isAdmin ? '/admin' : '/companies')
        : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/companies',
        builder: (context, state) => const CompanyRegisterPage(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const CompanySearchPage(),
      ),
      GoRoute(
        path: '/stock/:code',
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return StockDetailPage(code: code);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminCompanyProfileListPage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}