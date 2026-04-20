import 'dart:convert';
import 'package:http/http.dart' as http;

import '../domain/stock_detail_models.dart';

class StockDetailApiRepository {
  StockDetailApiRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'http://localhost:8080';

  Future<StockDetailSummary> fetchSummary(String code) async {
    final uri = Uri.parse('$baseUrl/api/stocks/$code');
    final res = await _client.get(uri, headers: const {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception('summary fetch failed: status=${res.statusCode}, body=${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;

    return StockDetailSummary(
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      market: (map['market'] ?? '').toString(),
      industry: (map['industry'] ?? map['sector'] ?? '').toString(),
      price: _toDouble(map['price']),
      changePct: _toDouble(map['changePct']),
      high: _toDouble(map['high']),
      low: _toDouble(map['low']),
      open: _toDouble(map['open']),
      close: _toDouble(map['close']),
      volume: _toDouble(map['volume']),
    );
  }

  Future<List<StockChartPoint>> fetchChart(String code) async {
    final uri = Uri.parse('$baseUrl/api/stocks/$code/chart');
    final res = await _client.get(uri, headers: const {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception('chart fetch failed: status=${res.statusCode}, body=${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('chart response invalid: $decoded');
    }

    return decoded.map<StockChartPoint>((e) {
      final map = e as Map<String, dynamic>;
      return StockChartPoint(
        date: (map['date'] ?? '').toString(),
        open: _toDouble(map['open']),
        high: _toDouble(map['high']),
        low: _toDouble(map['low']),
        close: _toDouble(map['close']),
        volume: _toDouble(map['volume']),
      );
    }).toList();
  }

  Future<List<StockNewsItem>> fetchNews(String code) async {
    final uri = Uri.parse('$baseUrl/api/stocks/$code/news');
    final res = await _client.get(uri, headers: const {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception('news fetch failed: status=${res.statusCode}, body=${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('news response invalid: $decoded');
    }

    return decoded.map<StockNewsItem>((e) {
      final map = e as Map<String, dynamic>;
      return StockNewsItem(
        title: (map['title'] ?? '').toString(),
        source: (map['source'] ?? '').toString(),
        publishedAt: (map['publishedAt'] ?? '').toString(),
        url: (map['url'] ?? '').toString(),
      );
    }).toList();
  }

  Future<StockMetrics> fetchMetrics(String code) async {
    final uri = Uri.parse('$baseUrl/api/stocks/$code/metrics');
    final res = await _client.get(uri, headers: const {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception('metrics fetch failed: status=${res.statusCode}, body=${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;

    return StockMetrics(
      per: _toDouble(map['per']),
      pbr: _toDouble(map['pbr']),
      roe: _toDouble(map['roe']),
      dividendYield: _toDouble(map['dividendYield']),
      marketCap: _toDouble(map['marketCap']),
    );
  }

  Future<StockCompanyInfo> fetchCompany(String code) async {
    final uri = Uri.parse('$baseUrl/api/stocks/$code/company');
    final res = await _client.get(uri, headers: const {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception('company fetch failed: status=${res.statusCode}, body=${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;

    return StockCompanyInfo(
      companyName: (map['companyName'] ?? '').toString(),
      market: (map['market'] ?? '').toString(),
      industry: (map['industry'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      website: (map['website'] ?? '').toString(),
      headquarters: (map['headquarters'] ?? '').toString(),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  void dispose() {
    _client.close();
  }
}