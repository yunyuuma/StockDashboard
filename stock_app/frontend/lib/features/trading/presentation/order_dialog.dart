import 'package:flutter/material.dart';

import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

Future<OrderResult?> showOrderDialog({
  required BuildContext context,
  required String stockCode,
  required String stockName,
  required double currentPrice,
  String initialSide = 'BUY',
}) async {
  final quantityController = TextEditingController(text: '100');
  final limitPriceController = TextEditingController(
    text: currentPrice.toStringAsFixed(0),
  );
  final repository = TradingRepository();

  String side = initialSide;
  String orderType = 'MARKET';
  bool loading = false;
  String? error;

  try {
    return await showDialog<OrderResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final quantity = int.tryParse(quantityController.text.trim());
              final limitPrice = double.tryParse(limitPriceController.text.trim());

              if (quantity == null || quantity <= 0) {
                setDialogState(() {
                  error = '数量は1以上で入力してください。';
                });
                return;
              }

              if (orderType == 'LIMIT' && (limitPrice == null || limitPrice <= 0)) {
                setDialogState(() {
                  error = '指値価格を入力してください。';
                });
                return;
              }

              setDialogState(() {
                loading = true;
                error = null;
              });

              try {
                final result = await repository.placeOrder(
                  stockCode: stockCode,
                  side: side,
                  orderType: orderType,
                  quantity: quantity,
                  limitPrice: orderType == 'LIMIT' ? limitPrice : null,
                  currentPrice: currentPrice,
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(result);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    error = e.toString().replaceFirst('Exception: ', '');
                    loading = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: Text('注文 $stockCode'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        stockName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '現在価格：¥${currentPrice.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'BUY', label: Text('買い')),
                        ButtonSegment(value: 'SELL', label: Text('売り')),
                      ],
                      selected: {side},
                      onSelectionChanged: loading
                          ? null
                          : (value) {
                              setDialogState(() {
                                side = value.first;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'MARKET', label: Text('成行')),
                        ButtonSegment(value: 'LIMIT', label: Text('指値')),
                      ],
                      selected: {orderType},
                      onSelectionChanged: loading
                          ? null
                          : (value) {
                              setDialogState(() {
                                orderType = value.first;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      enabled: !loading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '数量',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (orderType == 'LIMIT') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: limitPriceController,
                        enabled: !loading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '指値価格',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: Text(loading ? '注文中...' : '注文する'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    quantityController.dispose();
    limitPriceController.dispose();
    repository.dispose();
  }
}