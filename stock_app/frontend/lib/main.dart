import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/stock/presentation/company_register_page.dart';
import 'features/stock/presentation/company_search_page.dart';
import 'features/stock/presentation/stock_detail_page.dart';
import 'features/admin/presentation/admin_company_profile_list_page.dart';
import 'features/admin/presentation/admin_company_profile_edit_page.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {

    final GoRouter router = GoRouter(
      initialLocation: '/stocks',
      routes: [
        GoRoute(
          path: '/stocks',
          builder: (context, state) => const CompanyRegisterPage(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const CompanySearchPage(),
        ),
        GoRoute(
          path: '/stock/:code',
          builder: (context, state) {
            final code = state.pathParameters['code']!;
            return StockDetailPage(code: code);
          },
        ),
        GoRoute(
          path: '/admin/company-profiles',
          builder: (context, state) => const AdminCompanyProfileListPage(),
        ),
        GoRoute(
          path: '/admin/company-profiles/:stockCode',
          builder: (context, state) {
            final stockCode = state.pathParameters['stockCode']!;
            return AdminCompanyProfileEditPage(stockCode: stockCode);
          },
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Stock App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}