import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/admin_dashboard_repository.dart';

class AdminUsagePage extends StatefulWidget {
  const AdminUsagePage({super.key});

  @override
  State<AdminUsagePage> createState() => _AdminUsagePageState();
}

class _AdminUsagePageState extends State<AdminUsagePage> {
  final _repository = AdminDashboardRepository();

  bool _loading = true;
  String? _error;
  AdminDashboardSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await _repository.fetchSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          '利用状況',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: '再読込',
          ),
        ],
      ),
      body: Builder(
        builder: (_) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (summary == null) {
            return const Center(child: Text('利用状況がありません。'));
          }

          return GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: [
              _UsageCard(
                icon: Icons.people_alt_outlined,
                title: 'ユーザ数',
                value: '${summary.userCount}',
              ),
              _UsageCard(
                icon: Icons.admin_panel_settings_outlined,
                title: '管理者数',
                value: '${summary.adminCount}',
              ),
              _UsageCard(
                icon: Icons.star_border,
                title: 'お気に入り数',
                value: '${summary.favoriteCount}',
              ),
              _UsageCard(
                icon: Icons.format_list_bulleted,
                title: '銘柄数',
                value: '${summary.stockCount}',
              ),
              _UsageCard(
                icon: Icons.business,
                title: '企業情報数',
                value: '${summary.companyProfileCount}',
              ),
              _UsageCard(
                icon: Icons.security,
                title: '2段階認証ON',
                value: '${summary.twoFactorUserCount}',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEFF6FF),
              child: Icon(icon, color: const Color(0xFF2563EB)),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}