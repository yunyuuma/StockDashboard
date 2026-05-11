import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

class TradeHistoryPage extends StatefulWidget {
  const TradeHistoryPage({super.key});

  @override
  State<TradeHistoryPage> createState() => _TradeHistoryPageState();
}

class _TradeHistoryPageState extends State<TradeHistoryPage> {
  final TradingRepository _repository = TradingRepository();

  bool _loading = true;
  String? _error;
  List<TradeHistory> _trades = [];

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
      final trades = await _repository.fetchTrades();

      if (!mounted) return;

      setState(() {
        _trades = trades;
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

  String _yen(double value) => '¥${value.toStringAsFixed(0)}';

  String _sideLabel(String side) {
    return side == 'BUY' ? '買い' : '売り';
  }

  Color _sideColor(String side) {
    return side == 'BUY' ? Colors.red : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          '売買履歴',
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

          if (_trades.isEmpty) {
            return const Center(child: Text('売買履歴がありません。'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _trades.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final t = _trades[index];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: _sideColor(t.side).withOpacity(0.10),
                    child: Text(
                      _sideLabel(t.side),
                      style: TextStyle(
                        color: _sideColor(t.side),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    t.stockName.isNotEmpty
                        ? '${t.stockName} / ${_sideLabel(t.side)}'
                        : '${t.stockCode} / ${_sideLabel(t.side)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${t.stockCode} / ${t.market} / ${t.sector}\n${t.quantity}株 / ${t.tradedAt}',
                  ),
                  trailing: Text(
                    _yen(t.price),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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