import 'package:flutter/material.dart';
import '../../domain/company.dart';

class StockListCard extends StatelessWidget {
  const StockListCard({
    super.key,
    required this.company,
    required this.onTap,
    required this.onFavoriteTap,
    this.favoriteTooltip,
    this.showPriceInfo = false,
    this.onAiTap,
  });

  final Company company;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final String? favoriteTooltip;
  final bool showPriceInfo;
  final VoidCallback? onAiTap;

  Color _marketChipColor(String market) {
    switch (market) {
      case 'プライム':
        return const Color(0xFFE8F1FF);
      case 'スタンダード':
        return const Color(0xFFF3F4F6);
      case 'グロース':
        return const Color(0xFFEAFBF1);
      default:
        return const Color(0xFFF4F4F5);
    }
  }

  Color _marketTextColor(String market) {
    switch (market) {
      case 'プライム':
        return const Color(0xFF2563EB);
      case 'スタンダード':
        return const Color(0xFF4B5563);
      case 'グロース':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF52525B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlus = company.changePct >= 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    company.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            company.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onFavoriteTap,
                          icon: Icon(
                            company.favorite ? Icons.star : Icons.star_border,
                            color: company.favorite ? Colors.amber : Colors.grey,
                          ),
                          splashRadius: 20,
                          tooltip: favoriteTooltip,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _marketChipColor(company.market),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            company.market,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _marketTextColor(company.market),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            company.industry,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (showPriceInfo) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _metricBox(
                              title: '現在価格',
                              value: company.price > 0
                                  ? '¥${company.price.toStringAsFixed(0)}'
                                  : '-',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _metricBox(
                              title: '前日比',
                              value: company.price > 0
                                  ? '${isPlus ? '+' : ''}${company.changePct.toStringAsFixed(2)}%'
                                  : '-',
                              valueColor: company.price > 0
                                  ? (isPlus
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626))
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '銘柄詳細へ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey[500],
                            ),

                            const Spacer(),

                            TextButton.icon(
                              onPressed: onAiTap,
                              icon: const Icon(
                                Icons.smart_toy_outlined,
                                size: 18,
                              ),
                              label: const Text('AI相談'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricBox({
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}