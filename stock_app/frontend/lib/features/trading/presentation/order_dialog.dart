import 'package:flutter/material.dart';

import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

Future<OrderResult?> showOrderDialog({
  required BuildContext context,
  required String stockCode,
  required String stockName,
  required double currentPrice,
  String initialSide = 'BUY',
  String initialOrderType = 'MARKET',
  double? initialLimitPrice,
  double? initialStopPrice,
}) async {
  final quantityController = TextEditingController(text: '100');
  final limitPriceController = TextEditingController(
    text: (initialLimitPrice ?? currentPrice).toStringAsFixed(0),
  );
  final stopPriceController = TextEditingController(
    text: (initialStopPrice ?? currentPrice).toStringAsFixed(0),
  );

  final repository = TradingRepository();

  String side = initialSide;
  String orderType = initialOrderType;
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
              final stopPrice = double.tryParse(stopPriceController.text.trim());

              if (quantity == null || quantity <= 0) {
                setDialogState(() => error = '数量は1以上で入力してください。');
                return;
              }

              if (orderType == 'LIMIT' && (limitPrice == null || limitPrice <= 0)) {
                setDialogState(() => error = '指値価格を入力してください。');
                return;
              }

              if (orderType == 'STOP' && (stopPrice == null || stopPrice <= 0)) {
                setDialogState(() => error = '逆指値価格を入力してください。');
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
                  stopPrice: orderType == 'STOP' ? stopPrice : null,
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
                    DropdownButtonFormField<String>(
                      value: orderType,
                      decoration: const InputDecoration(
                        labelText: '注文種別',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MARKET', child: Text('成行')),
                        DropdownMenuItem(value: 'LIMIT', child: Text('指値')),
                        DropdownMenuItem(value: 'STOP', child: Text('逆指値')),
                      ],
                      onChanged: loading
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() {
                                orderType = value;
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
                    if (orderType == 'STOP') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: stopPriceController,
                        enabled: !loading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '逆指値価格',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _orderHelp(side, orderType),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
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
    stopPriceController.dispose();
    repository.dispose();
  }
}

Future<OrderResult?> showAlgoOrderDialog({
  required BuildContext context,
  required String stockCode,
  required String stockName,
  required double currentPrice,
}) async {
  final quantityController = TextEditingController(text: '100');
  final entryController = TextEditingController(text: currentPrice.toStringAsFixed(0));
  final profitController = TextEditingController(text: (currentPrice * 1.05).toStringAsFixed(0));
  final stopController = TextEditingController(text: (currentPrice * 0.95).toStringAsFixed(0));

  final repository = TradingRepository();

  String algoType = 'IFD';
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
              final entry = double.tryParse(entryController.text.trim());
              final profit = double.tryParse(profitController.text.trim());
              final stop = double.tryParse(stopController.text.trim());

              if (quantity == null || quantity <= 0) {
                setDialogState(() => error = '数量は1以上で入力してください。');
                return;
              }

              if ((algoType == 'IFD' || algoType == 'IFDOCO') &&
                  (entry == null || entry <= 0)) {
                setDialogState(() => error = '買い指値価格を入力してください。');
                return;
              }

              if ((algoType == 'IFD' || algoType == 'OCO' || algoType == 'IFDOCO') &&
                  (profit == null || profit <= 0)) {
                setDialogState(() => error = '利確価格を入力してください。');
                return;
              }

              if ((algoType == 'OCO' || algoType == 'IFDOCO') &&
                  (stop == null || stop <= 0)) {
                setDialogState(() => error = '損切価格を入力してください。');
                return;
              }

              setDialogState(() {
                loading = true;
                error = null;
              });

              try {
                final result = await repository.placeAlgoOrder(
                  stockCode: stockCode,
                  algoType: algoType,
                  quantity: quantity,
                  currentPrice: currentPrice,
                  entryLimitPrice: algoType == 'IFD' || algoType == 'IFDOCO' ? entry : null,
                  profitLimitPrice: profit,
                  stopPrice: algoType == 'OCO' || algoType == 'IFDOCO' ? stop : null,
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
              title: Text('アルゴ注文 $stockCode'),
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
                    DropdownButtonFormField<String>(
                      value: algoType,
                      decoration: const InputDecoration(
                        labelText: 'アルゴ注文種別',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'IFD', child: Text('IFD')),
                        DropdownMenuItem(value: 'OCO', child: Text('OCO')),
                        DropdownMenuItem(value: 'IFDOCO', child: Text('IFDOCO')),
                      ],
                      onChanged: loading
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() {
                                algoType = value;
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
                    if (algoType == 'IFD' || algoType == 'IFDOCO') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: entryController,
                        enabled: !loading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '買い指値価格',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: profitController,
                      enabled: !loading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '利確価格',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (algoType == 'OCO' || algoType == 'IFDOCO') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: stopController,
                        enabled: !loading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '損切価格',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _algoHelp(algoType),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
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
    entryController.dispose();
    profitController.dispose();
    stopController.dispose();
    repository.dispose();
  }
}

String _algoHelp(String algoType) {
  switch (algoType) {
    case 'IFD':
      return 'IFD：買い注文が約定した後、利確売り注文を自動登録します。';
    case 'OCO':
      return 'OCO：利確売りと損切売りを同時に出し、片方が約定したらもう片方を取消します。';
    case 'IFDOCO':
      return 'IFDOCO：買い約定後、利確売りと損切売りを同時登録します。';
    default:
      return '';
  }
}

String _orderHelp(String side, String orderType) {
  if (orderType == 'MARKET') return '成行注文：現在価格で即時約定します。';

  if (orderType == 'LIMIT') {
    return side == 'BUY'
        ? '指値買い：現在価格が指値以下なら約定します。'
        : '指値売り：現在価格が指値以上なら約定します。';
  }

  return side == 'BUY'
      ? '逆指値買い：現在価格が逆指値以上になったら約定します。'
      : '逆指値売り：現在価格が逆指値以下になったら約定します。';
}