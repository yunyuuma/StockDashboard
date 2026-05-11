import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/ai_advisor_repository.dart';
import '../domain/ai_trading_review_models.dart';

class AiTradingReviewPage extends StatefulWidget {
  const AiTradingReviewPage({super.key});

  @override
  State<AiTradingReviewPage> createState() => _AiTradingReviewPageState();
}

class _AiTradingReviewPageState extends State<AiTradingReviewPage> {
  final AiAdvisorRepository _repository = AiAdvisorRepository();

  bool _loading = true;
  String? _error;
  AiTradingReview? _review;

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
      final review = await _repository.fetchTradingReview();

      if (!mounted) return;

      setState(() {
        _review = review;
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
    final review = _review;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'AI売買レビュー',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/ai-advisor'),
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

          if (review == null) {
            return const Center(child: Text('AI売買レビューデータがありません。'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SummaryCard(review: review),
              const SizedBox(height: 14),
              _AdviceCard(
                icon: Icons.thumb_up_alt_outlined,
                title: '良い点',
                items: review.goodPoints,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(height: 14),
              _AdviceCard(
                icon: Icons.error_outline,
                title: '改善点',
                items: review.weakPoints,
                color: const Color(0xFFDC2626),
              ),
              const SizedBox(height: 14),
              _AdviceCard(
                icon: Icons.lightbulb_outline,
                title: '改善提案',
                items: review.suggestions,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 14),
              _AdviceCard(
                icon: Icons.warning_amber_outlined,
                title: '注意事項',
                items: review.warnings,
                color: const Color(0xFFD97706),
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
    required this.review,
  });

  final AiTradingReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(
                Icons.smart_toy_outlined,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '売買履歴AIレビュー',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.summary,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniChip(label: '取引', value: '${review.tradeCount}件'),
                      _MiniChip(label: '買い', value: '${review.buyCount}件'),
                      _MiniChip(label: '売り', value: '${review.sellCount}件'),
                    ],
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label：$value',
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
    required this.color,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;

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
                '該当する内容はありません。',
                style: TextStyle(color: Colors.black54),
              )
            else
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