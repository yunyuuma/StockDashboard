import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/ai_advisor_repository.dart';
import '../domain/ai_stock_advisor_models.dart';

class AiStockAdvisorPage extends StatefulWidget {
  const AiStockAdvisorPage({
    super.key,
    required this.stockCode,
  });

  final String stockCode;

  @override
  State<AiStockAdvisorPage> createState() => _AiStockAdvisorPageState();
}

class _AiStockAdvisorPageState extends State<AiStockAdvisorPage> {
  final AiAdvisorRepository _repository = AiAdvisorRepository();

  bool _loading = true;
  String? _error;
  AiStockAdvisorResult? _result;

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
      final result = await _repository.fetchStockAnalysis(widget.stockCode);

      if (!mounted) return;

      setState(() {
        _result = result;
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

  Color _riskColor(String riskLevel) {
    switch (riskLevel) {
      case 'HIGH':
        return const Color(0xFFDC2626);
      case 'MIDDLE':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF16A34A);
    }
  }

  String _riskLabel(String riskLevel) {
    switch (riskLevel) {
      case 'HIGH':
        return '注意度高め';
      case 'MIDDLE':
        return '標準';
      default:
        return '安定';
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          '銘柄AI相談',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: '再分析',
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

          if (result == null) {
            return const Center(child: Text('銘柄AI分析データがありません。'));
          }

          final riskColor = _riskColor(result.riskLevel);

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
                        backgroundColor: riskColor.withOpacity(0.12),
                        child: Text(
                          result.stockCode,
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.stockName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${result.market} / ${result.sector}',
                              style: const TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _riskLabel(result.riskLevel),
                              style: TextStyle(
                                color: riskColor,
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
              _SummaryCard(
                color: riskColor,
                summary: result.summary,
              ),
              const SizedBox(height: 14),
              _AdviceCard(
                icon: Icons.analytics_outlined,
                title: 'AI分析',
                items: result.analysis,
              ),
              const SizedBox(height: 14),
              _AdviceCard(
                icon: Icons.check_circle_outline,
                title: '確認ポイント',
                items: result.checkPoints,
              ),
              const SizedBox(height: 14),
              _AdviceCard(
                icon: Icons.warning_amber_outlined,
                title: '注意事項',
                items: result.warnings,
                warning: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.color,
    required this.summary,
  });

  final Color color;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                summary,
                style: const TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.icon,
    required this.title,
    required this.items,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFD97706) : const Color(0xFF2563EB);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}