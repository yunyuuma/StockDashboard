import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminUsagePage extends StatelessWidget {
  const AdminUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _UsageCard(
            icon: Icons.people_alt_outlined,
            title: 'ユーザ数',
            value: 'API接続後に表示',
          ),
          SizedBox(height: 14),
          _UsageCard(
            icon: Icons.star_border,
            title: 'お気に入り登録数',
            value: 'API接続後に表示',
          ),
          SizedBox(height: 14),
          _UsageCard(
            icon: Icons.business,
            title: '企業情報登録数',
            value: 'API接続後に表示',
          ),
        ],
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
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(icon, color: Color(0xFF2563EB)),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              value,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}