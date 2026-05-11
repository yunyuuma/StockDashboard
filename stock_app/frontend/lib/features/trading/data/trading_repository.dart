import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../stock/domain/app_session.dart';
import '../domain/trading_models.dart';

class TradingRepository {
  TradingRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'http://127.0.0.1:8080';

  Map<String, String> get _headers {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (AppSession.token != null && AppSession.token!.isNotEmpty)
        'Authorization': 'Bearer ${AppSession.token}',
    };
  }

  Future<TradingSummary> fetchSummary() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/trading/summary'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('売買サマリー取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    return TradingSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<TradingPosition>> fetchPositions() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/trading/positions'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('保有銘柄取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('保有銘柄レスポンス不正: $decoded');
    }

    return decoded
        .map<TradingPosition>((e) => TradingPosition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TradeHistory>> fetchTrades() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/trading/trades'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('売買履歴取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('売買履歴レスポンス不正: $decoded');
    }

    return decoded
        .map<TradeHistory>((e) => TradeHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderResult> placeOrder({
    required String stockCode,
    required String side,
    required String orderType,
    required int quantity,
    double? limitPrice,
    double? stopPrice,
    required double currentPrice,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/trading/orders'),
      headers: _headers,
      body: jsonEncode({
        'stockCode': stockCode,
        'side': side,
        'orderType': orderType,
        'quantity': quantity,
        'limitPrice': limitPrice,
        'stopPrice': stopPrice,
        'currentPrice': currentPrice,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('注文失敗: status=${res.statusCode}, body=${res.body}');
    }

    return OrderResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<OrderBook> fetchOrderBook({
    required String stockCode,
    required double currentPrice,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/trading/order-book/$stockCode?currentPrice=$currentPrice',
    );

    final res = await _client.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('板情報取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    return OrderBook.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<TradingOrder>> fetchOrders() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/trading/orders'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('注文一覧取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('注文一覧レスポンス不正: $decoded');
    }

    return decoded
        .map<TradingOrder>((e) => TradingOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TradingOrder>> fetchOpenOrders() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/trading/orders/open'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('未約定注文取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('未約定注文レスポンス不正: $decoded');
    }

    return decoded
        .map<TradingOrder>((e) => TradingOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelOrder(int orderId) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/api/trading/orders/$orderId'),
      headers: _headers,
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('注文取消失敗: status=${res.statusCode}, body=${res.body}');
    }
  }

  Future<int> checkOpenOrders() async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/trading/orders/check'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('未約定再判定失敗: status=${res.statusCode}, body=${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return _toInt(map['filledCount']);
  }

  Future<OrderResult> placeAlgoOrder({
    required String stockCode,
    required String algoType,
    required int quantity,
    required double currentPrice,
    double? entryLimitPrice,
    double? profitLimitPrice,
    double? stopPrice,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/trading/algo-orders'),
      headers: _headers,
      body: jsonEncode({
        'stockCode': stockCode,
        'algoType': algoType,
        'quantity': quantity,
        'currentPrice': currentPrice,
        'entryLimitPrice': entryLimitPrice,
        'profitLimitPrice': profitLimitPrice,
        'stopPrice': stopPrice,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('アルゴ注文失敗: status=${res.statusCode}, body=${res.body}');
    }

    return OrderResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  void dispose() {
    _client.close();
  }
}