import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

class TradingHomePage extends StatefulWidget {
  const TradingHomePage({super.key});

  @override
  State<TradingHomePage> createState() => _TradingHomePageState();
}

class _TradingHomePageState extends State<TradingHomePage> {
  final TradingRepository _repository = TradingRepository();

  bool _loading = true;
  String? _error;
  TradingSummary? _summary;

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

  String _yen(double value) {
    return '¥${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
      leading: IconButton(
        onPressed: () => context.go('/mypage'),
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text(
        '疑似売買',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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
            return const Center(child: Text('疑似売買データがありません。'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '仮想残高',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _yen(summary.cash),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SmallSummaryCard(
                          title: '保有銘柄',
                          value: '${summary.positionCount}',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallSummaryCard(
                          title: '売買履歴',
                          value: '${summary.tradeCount}',
                          icon: Icons.history,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _MenuCard(
                    icon: Icons.receipt_long_outlined,
                    title: '注文一覧',
                    description: '未約定・約定済み・取消済みの注文を確認します。',
                    onTap: () => context.go('/trading/orders'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MenuCard(
                icon: Icons.inventory_2_outlined,
                title: '保有銘柄一覧',
                description: '現在保有している銘柄・数量・平均取得単価を確認します。',
                onTap: () => context.go('/trading/positions'),
              ),
              const SizedBox(height: 14),
              _MenuCard(
                icon: Icons.history,
                title: '売買履歴',
                description: '成行・指値注文の約定履歴を確認します。',
                onTap: () => context.go('/trading/trades'),
              ),
              const SizedBox(height: 14),
              _MenuCard(
                icon: Icons.pie_chart_outline,
                title: 'ポートフォリオ',
                description: '総資産・保有評価額・資産推移を確認します。',
                onTap: () => context.go('/trading/portfolio'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SmallSummaryCard extends StatelessWidget {
  const _SmallSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
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

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Icon(icon, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}