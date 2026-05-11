import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final TradingRepository _repository = TradingRepository();

  bool _loading = true;
  String? _error;
  List<TradingOrder> _orders = [];

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
      final orders = await _repository.fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  Future<void> _check() async {
    try {
      final count = await _repository.checkOpenOrders();
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('未約定注文を再判定しました。約定：$count件')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('再判定失敗: $e')),
      );
    }
  }

  Future<void> _cancel(TradingOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('注文取消'),
        content: Text(
          '${order.stockName.isNotEmpty ? order.stockName : order.stockCode} の注文を取消しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _repository.cancelOrder(order.orderId);
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注文を取消しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('取消失敗: $e')),
      );
    }
  }

  String _yen(double? value) {
    if (value == null || value <= 0) return '-';
    return '¥${value.toStringAsFixed(0)}';
  }

  String _sideLabel(String side) => side == 'BUY' ? '買い' : '売り';

  String _typeLabel(String type) {
    switch (type) {
      case 'MARKET':
        return '成行';
      case 'LIMIT':
        return '指値';
      case 'STOP':
        return '逆指値';
      default:
        return type;
    }
  }

  String _algoLabel(String value) {
    switch (value) {
      case 'IFD':
        return 'IFD';
      case 'OCO':
        return 'OCO';
      case 'IFDOCO':
        return 'IFDOCO';
      case 'NONE':
      case '':
        return '通常注文';
      default:
        return value;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'OPEN':
        return '未約定';
      case 'FILLED':
        return '約定済み';
      case 'CANCELED':
        return '取消済み';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFF2563EB);
      case 'FILLED':
        return const Color(0xFF16A34A);
      case 'CANCELED':
        return Colors.black45;
      default:
        return Colors.black54;
    }
  }

  List<TradingOrder> _filter(String status) {
    return _orders.where((e) => e.status == status).toList();
  }

  Widget _orderList(List<TradingOrder> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('注文がありません。'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final o = orders[index];
        final isOpen = o.status == 'OPEN';

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
                      backgroundColor: _statusColor(o.status).withOpacity(0.12),
                      child: Text(
                        _sideLabel(o.side),
                        style: TextStyle(
                          color: _statusColor(o.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        o.stockName.isNotEmpty ? o.stockName : o.stockCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      _statusLabel(o.status),
                      style: TextStyle(
                        color: _statusColor(o.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${o.stockCode} / ${o.market} / ${o.sector}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_typeLabel(o.orderType)} / ${o.quantity}株 / 現在価格 ${_yen(o.currentPrice)}',
                ),
                if (o.algoType.isNotEmpty && o.algoType != 'NONE') ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _infoChip('アルゴ', _algoLabel(o.algoType)),
                    if (o.groupId.isNotEmpty)
                      _infoChip('グループ', o.groupId.substring(0, 8)),
                    if (o.parentOrderId != null)
                      _infoChip('親注文', '#${o.parentOrderId}'),
                  ],
                ),
              ],
                if (o.limitPrice != null) Text('指値価格：${_yen(o.limitPrice)}'),
                if (o.stopPrice != null) Text('逆指値価格：${_yen(o.stopPrice)}'),
                const SizedBox(height: 8),
                Text(
                  '注文日時：${o.orderedAt}',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                if (isOpen) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancel(o),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('注文を取消'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

Widget _infoChip(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFBFDBFE)),
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

  @override
  Widget build(BuildContext context) {
    final open = _filter('OPEN');
    final filled = _filter('FILLED');
    final canceled = _filter('CANCELED');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text(
            '注文一覧',
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
              onPressed: _check,
              icon: const Icon(Icons.playlist_add_check),
              tooltip: '未約定再判定',
            ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: '再読込',
            ),
          ],
          bottom: TabBar(
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFF2563EB),
            tabs: [
              Tab(text: '未約定(${open.length})'),
              Tab(text: '約定済み(${filled.length})'),
              Tab(text: '取消済み(${canceled.length})'),
            ],
          ),
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
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return TabBarView(
              children: [
                _orderList(open),
                _orderList(filled),
                _orderList(canceled),
              ],
            );
          },
        ),
      ),
    );
  }
}