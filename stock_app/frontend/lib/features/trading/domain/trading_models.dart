class TradingSummary {
  final double cash;
  final int positionCount;
  final int tradeCount;

  const TradingSummary({
    required this.cash,
    required this.positionCount,
    required this.tradeCount,
  });

  factory TradingSummary.fromJson(Map<String, dynamic> json) {
    return TradingSummary(
      cash: _toDouble(json['cash']),
      positionCount: _toInt(json['positionCount']),
      tradeCount: _toInt(json['tradeCount']),
    );
  }
}
class TradingOrder {
  final int orderId;
  final String stockCode;
  final String stockName;
  final String market;
  final String sector;
  final String side;
  final String orderType;
  final String algoType;
  final String groupId;
  final int quantity;
  final int? parentOrderId;
  final double? limitPrice;
  final double? stopPrice;
  final double currentPrice;
  final String status;
  final String orderedAt;
  final String? filledAt;
  final String? canceledAt;

  const TradingOrder({
    required this.orderId,
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.sector,
    required this.side,
    required this.orderType,
    required this.algoType,
    required this.groupId,
    required this.parentOrderId,
    required this.quantity,
    required this.limitPrice,
    required this.stopPrice,
    required this.currentPrice,
    required this.status,
    required this.orderedAt,
    required this.filledAt,
    required this.canceledAt,
  });

  factory TradingOrder.fromJson(Map<String, dynamic> json) {
    return TradingOrder(
      orderId: _toInt(json['orderId']),
      stockCode: (json['stockCode'] ?? '').toString(),
      stockName: (json['stockName'] ?? '').toString(),
      market: (json['market'] ?? '').toString(),
      sector: (json['sector'] ?? '').toString(),
      side: (json['side'] ?? '').toString(),
      orderType: (json['orderType'] ?? '').toString(),
      quantity: _toInt(json['quantity']),
      limitPrice: json['limitPrice'] == null ? null : _toDouble(json['limitPrice']),
      stopPrice: json['stopPrice'] == null ? null : _toDouble(json['stopPrice']),
      currentPrice: _toDouble(json['currentPrice']),
      status: (json['status'] ?? '').toString(),
      orderedAt: (json['orderedAt'] ?? '').toString(),
      filledAt: json['filledAt']?.toString(),
      canceledAt: json['canceledAt']?.toString(),
      algoType: (json['algoType'] ?? 'NONE').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      parentOrderId: json['parentOrderId'] == null
          ? null
          : _toInt(json['parentOrderId']),
    );
  }
}

class TradingPosition {
  final String stockCode;
  final String stockName;
  final String market;
  final String sector;
  final int quantity;
  final double averagePrice;
  final double currentPrice;
  final double valuationAmount;
  final double profitLoss;
  final double profitLossRate;

  const TradingPosition({
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.sector,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.valuationAmount,
    required this.profitLoss,
    required this.profitLossRate,
  });

  factory TradingPosition.fromJson(Map<String, dynamic> json) {
    return TradingPosition(
      stockCode: (json['stockCode'] ?? '').toString(),
      stockName: (json['stockName'] ?? '').toString(),
      market: (json['market'] ?? '').toString(),
      sector: (json['sector'] ?? '').toString(),
      quantity: _toInt(json['quantity']),
      averagePrice: _toDouble(json['averagePrice']),
      currentPrice: _toDouble(json['currentPrice']),
      valuationAmount: _toDouble(json['valuationAmount']),
      profitLoss: _toDouble(json['profitLoss']),
      profitLossRate: _toDouble(json['profitLossRate']),
    );
  }
}

class TradeHistory {
  final int id;
  final String stockCode;
  final String stockName;
  final String market;
  final String sector;
  final String side;
  final int quantity;
  final double price;
  final String tradedAt;

  const TradeHistory({
    required this.id,
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.sector,
    required this.side,
    required this.quantity,
    required this.price,
    required this.tradedAt,
  });

  factory TradeHistory.fromJson(Map<String, dynamic> json) {
    return TradeHistory(
      id: _toInt(json['id']),
      stockCode: (json['stockCode'] ?? '').toString(),
      stockName: (json['stockName'] ?? '').toString(),
      market: (json['market'] ?? '').toString(),
      sector: (json['sector'] ?? '').toString(),
      side: (json['side'] ?? '').toString(),
      quantity: _toInt(json['quantity']),
      price: _toDouble(json['price']),
      tradedAt: (json['tradedAt'] ?? '').toString(),
    );
  }
}

class OrderResult {
  final int orderId;
  final String stockCode;
  final String side;
  final String orderType;
  final int quantity;
  final double? limitPrice;
  final double currentPrice;
  final String status;
  final String message;

  const OrderResult({
    required this.orderId,
    required this.stockCode,
    required this.side,
    required this.orderType,
    required this.quantity,
    required this.limitPrice,
    required this.currentPrice,
    required this.status,
    required this.message,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    return OrderResult(
      orderId: _toInt(json['orderId']),
      stockCode: (json['stockCode'] ?? '').toString(),
      side: (json['side'] ?? '').toString(),
      orderType: (json['orderType'] ?? '').toString(),
      quantity: _toInt(json['quantity']),
      limitPrice: json['limitPrice'] == null ? null : _toDouble(json['limitPrice']),
      currentPrice: _toDouble(json['currentPrice']),
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class OrderBook {
  final String stockCode;
  final double currentPrice;
  final List<OrderBookRow> sellBoard;
  final List<OrderBookRow> buyBoard;

  const OrderBook({
    required this.stockCode,
    required this.currentPrice,
    required this.sellBoard,
    required this.buyBoard,
  });

  factory OrderBook.fromJson(Map<String, dynamic> json) {
    return OrderBook(
      stockCode: (json['stockCode'] ?? '').toString(),
      currentPrice: _toDouble(json['currentPrice']),
      sellBoard: ((json['sellBoard'] ?? []) as List)
          .map((e) => OrderBookRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      buyBoard: ((json['buyBoard'] ?? []) as List)
          .map((e) => OrderBookRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderBookRow {
  final double price;
  final int quantity;

  const OrderBookRow({
    required this.price,
    required this.quantity,
  });

  factory OrderBookRow.fromJson(Map<String, dynamic> json) {
    return OrderBookRow(
      price: _toDouble(json['price']),
      quantity: _toInt(json['quantity']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}