import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/stock/presentation/company_register_page.dart';
import 'features/stock/presentation/company_search_page.dart';
import 'features/stock/presentation/stock_detail_page.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {

    final router = GoRouter(
      routes: [

        // 最初の画面（お気に入り登録）
        GoRoute(
          path: '/',
          builder: (context, state) => const CompanyRegisterPage(),
        ),

        // 株価画面
        GoRoute(
          path: '/stocks',
          builder: (context, state) => const CompanySearchPage(),
        ),

        // 銘柄詳細
        GoRoute(
          path: '/stock/:code',
          builder: (context, state) {

            final code = state.pathParameters['code']!;

            return StockDetailPage(
              code: code,
            );
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