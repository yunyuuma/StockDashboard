import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

class PositionListPage extends StatefulWidget {
  const PositionListPage({super.key});

  @override
  State<PositionListPage> createState() => _PositionListPageState();
}

class _PositionListPageState extends State<PositionListPage> {
  final TradingRepository _repository = TradingRepository();

  bool _loading = true;
  String? _error;
  List<TradingPosition> _positions = [];

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
      final positions = await _repository.fetchPositions();

      if (!mounted) return;

      setState(() {
        _positions = positions;
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

  Widget _miniInfo(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          '保有銘柄',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/trading'),
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

          if (_positions.isEmpty) {
            return const Center(child: Text('保有銘柄がありません。'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _positions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final p = _positions[index];

              final bool isPlus = p.profitLoss >= 0;
              final Color pnlColor =
                  isPlus ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              p.stockCode,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.stockName.isNotEmpty
                                      ? p.stockName
                                      : p.stockCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${p.stockCode} / ${p.market} / ${p.sector}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _miniInfo('数量', '${p.quantity}株'),
                          ),
                          Expanded(
                            child: _miniInfo(
                              '平均取得単価',
                              _yen(p.averagePrice),
                            ),
                          ),
                          Expanded(
                            child: _miniInfo(
                              '現在価格',
                              _yen(p.currentPrice),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _miniInfo(
                              '評価額',
                              _yen(p.valuationAmount),
                            ),
                          ),
                          Expanded(
                            child: _miniInfo(
                              '含み損益',
                              '${isPlus ? '+' : ''}${_yen(p.profitLoss)}',
                              valueColor: pnlColor,
                            ),
                          ),
                          Expanded(
                            child: _miniInfo(
                              '損益率',
                              '${isPlus ? '+' : ''}${p.profitLossRate.toStringAsFixed(2)}%',
                              valueColor: pnlColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}