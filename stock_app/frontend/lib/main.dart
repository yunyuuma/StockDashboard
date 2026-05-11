import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/stock/domain/app_session.dart';
import 'features/stock/presentation/login_page.dart';
import 'features/admin/presentation/admin_guard_page.dart';
import 'features/admin/presentation/admin_home_page.dart';
import 'features/admin/presentation/admin_user_management_page.dart';
import 'features/admin/presentation/admin_usage_page.dart';
import 'features/admin/presentation/admin_stock_management_page.dart';
import 'features/stock/presentation/register_page.dart';
import 'features/stock/presentation/company_register_page.dart';
import 'features/stock/presentation/company_search_page.dart';
import 'features/stock/presentation/stock_detail_page.dart';
import 'features/stock/presentation/my_page.dart';
import 'features/admin/presentation/admin_company_profile_list_page.dart';
import 'features/admin/presentation/admin_company_profile_edit_page.dart';
import 'features/trading/presentation/trading_home_page.dart';
import 'features/trading/presentation/position_list_page.dart';
import 'features/trading/presentation/trade_history_page.dart';
import 'features/trading/presentation/order_list_page.dart';
import 'features/trading/presentation/portfolio_page.dart';
import 'features/ai/presentation/ai_advisor_page.dart';
import 'features/ai/presentation/ai_stock_advisor_page.dart';
import 'features/ai/presentation/ai_trading_review_page.dart';
import 'features/ai/presentation/ai_chat_page.dart';

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
        path: '/mypage',
        builder: (context, state) => const MyPage(),
      ),

      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminGuardPage(
          child: AdminHomePage(),
        ),
      ),
      GoRoute(
        path: '/admin/company-profiles',
        builder: (context, state) => const AdminGuardPage(
          child: AdminCompanyProfileListPage(),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminGuardPage(
          child: AdminUserManagementPage(),
        ),
      ),
      GoRoute(
        path: '/admin/company-profiles/:stockCode',
        builder: (context, state) {
          final stockCode = state.pathParameters['stockCode']!;

          return AdminGuardPage(
            child: AdminCompanyProfileEditPage(
              stockCode: stockCode,
            ),
          );
        },
      ),
      GoRoute(
        path: '/admin/usage',
        builder: (context, state) => const AdminGuardPage(
          child: AdminUsagePage(),
        ),
      ),
      GoRoute(
        path: '/admin/stocks',
        builder: (context, state) => const AdminGuardPage(
          child: AdminStockManagementPage(),
        ),
      ),
      GoRoute(
        path: '/trading',
        builder: (context, state) => const TradingHomePage(),
      ),
      GoRoute(
        path: '/trading/positions',
        builder: (context, state) => const PositionListPage(),
      ),
      GoRoute(
        path: '/trading/trades',
        builder: (context, state) => const TradeHistoryPage(),
      ),
      GoRoute(
        path: '/trading/orders',
        builder: (context, state) => const OrderListPage(),
      ),
      GoRoute(
        path: '/trading/portfolio',
        builder: (context, state) => const PortfolioPage(),
      ),
      GoRoute(
        path: '/ai-advisor',
        builder: (context, state) => const AiAdvisorPage(),
      ),
      GoRoute(
        path: '/ai-advisor/stocks/:code',
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return AiStockAdvisorPage(stockCode: code);
        },
      ),
      GoRoute(
        path: '/ai-advisor/trading-review',
        builder: (context, state) => const AiTradingReviewPage(),
      ),
      GoRoute(
        path: '/ai-advisor/chat',
        builder: (context, state) {
          final stockCode = state.uri.queryParameters['stockCode'];
          return AiChatPage(stockCode: stockCode);
        },
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