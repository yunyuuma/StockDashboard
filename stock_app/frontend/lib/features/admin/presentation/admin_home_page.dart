import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../stock/domain/app_session.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static const String baseUrl = 'http://127.0.0.1:8080';

  Future<void> _syncStocks(BuildContext context) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/admin/stocks/sync'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (AppSession.token != null &&
              AppSession.token!.isNotEmpty)
            'Authorization': 'Bearer ${AppSession.token}',
        },
      );

      if (!context.mounted) return;

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.body.isEmpty ? '銘柄同期が完了しました。' : res.body,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '同期失敗 status=${res.statusCode}\n${res.body}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('通信エラー: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          '管理者画面',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.go('/mypage'),
            icon: const Icon(Icons.person),
            tooltip: 'マイページ',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AdminHeaderCard(
            userName: AppSession.name ?? '管理者',
            email: AppSession.email ?? '',
          ),

          const SizedBox(height: 18),

          _AdminMenuCard(
            icon: Icons.business,
            title: '企業情報管理',
            description:
                '企業概要・Webサイト・検索キーワード・Structured補完を管理します。',
            badge: 'Structured補完',
            onTap: () => context.go('/admin/company-profiles'),
          ),

          const SizedBox(height: 14),

          _AdminMenuCard(
            icon: Icons.people_alt_outlined,
            title: 'ユーザ管理',
            description: 'ユーザ一覧、権限、登録状況を確認します。',
            badge: '権限管理',
            onTap: () => context.go('/admin/users'),
          ),

          const SizedBox(height: 14),

          _AdminMenuCard(
            icon: Icons.analytics_outlined,
            title: '利用状況',
            description: '登録ユーザ数、お気に入り数、企業情報登録数を確認します。',
            badge: '利用状況',
            onTap: () => context.go('/admin/usage'),
          ),

          const SizedBox(height: 14),

          _AdminMenuCard(
            icon: Icons.format_list_bulleted,
            title: '銘柄管理',
            description: '銘柄の追加・編集・削除を管理します。',
            badge: '追加/削除',
            onTap: () => context.go('/admin/stocks'),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _syncStocks(context),
              icon: const Icon(Icons.sync),
              label: const Text(
                '銘柄同期（API → DB）',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminHeaderCard extends StatelessWidget {
  const _AdminHeaderCard({
    required this.userName,
    required this.email,
  });

  final String userName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor:
                  const Color(0xFF2563EB).withOpacity(0.12),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF2563EB),
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius:
                          BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '管理者',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor:
                    const Color(0xFF2563EB)
                        .withOpacity(0.10),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFF2563EB),
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration:
                              BoxDecoration(
                            color: const Color(
                                0xFFF1F5F9),
                            borderRadius:
                                BorderRadius.circular(
                                    999),
                          ),
                          child: Text(
                            badge,
                            style:
                                const TextStyle(
                              fontSize: 11,
                              color:
                                  Colors.black54,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}