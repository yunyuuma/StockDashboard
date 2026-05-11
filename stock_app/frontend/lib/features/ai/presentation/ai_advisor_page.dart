import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/ai_advisor_repository.dart';
import '../domain/ai_advisor_models.dart';

class AiAdvisorPage extends StatefulWidget {
  const AiAdvisorPage({super.key});

  @override
  State<AiAdvisorPage> createState() => _AiAdvisorPageState();
}

class _AiAdvisorPageState extends State<AiAdvisorPage> {
  final AiAdvisorRepository _repository = AiAdvisorRepository();

  bool _loading = true;
  String? _error;
  AiAdvisorResult? _result;

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
      final result = await _repository.fetchAnalysis();

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
        return 'リスク高め';
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
          'AI相談',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/companies'),
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
            return const Center(child: Text('AI分析データがありません。'));
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
                        child: Icon(
                          Icons.smart_toy_outlined,
                          color: riskColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AIポートフォリオ診断',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _riskLabel(result.riskLevel),
                              style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              result.summary,
                              style: const TextStyle(
                                color: Colors.black87,
                                height: 1.4,
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

              _NavigationCard(
                icon: Icons.book_online,
                title: '履歴レビュー',
                description: '売買履歴から、買い癖・売り癖・改善点を分析します。',
                onTap: () => context.go('/ai-advisor/trading-review'),
              ),

              const SizedBox(height: 14),
              _NavigationCard(
                icon: Icons.chat_bubble_outline,
                title: 'AIチャット',
                description: '株価・保有銘柄・疑似売買について日本語で相談できます。',
                onTap: () => context.go('/ai-advisor/chat'),
              ),

              const SizedBox(height: 14),

              _AdviceCard(
                icon: Icons.pie_chart_outline,
                title: 'ポートフォリオ分析',
                items: result.portfolioAdvice,
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

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
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
              const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(
                  Icons.book_online,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
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
            if (items.isEmpty)
              const Text(
                '分析できるデータがまだありません。',
                style: TextStyle(color: Colors.black54),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: color,
                      ),
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