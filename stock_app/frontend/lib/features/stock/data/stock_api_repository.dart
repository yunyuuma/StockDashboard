import 'dart:convert';
import 'package:http/http.dart' as http;

import '../domain/company.dart';

class StockApiRepository {
  StockApiRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'http://localhost:8080';

  Future<List<Company>> fetchStocks({
    required int page,
    int size = 30,
    String? query,
    String? market,
  }) async {
    final uri = Uri.parse('$baseUrl/api/stocks').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (market != null && market.trim().isNotEmpty) 'market': market.trim(),
      },
    );

    final res = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception(
        'stocks fetch failed: status=${res.statusCode}, body=${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('stocks response invalid: $decoded');
    }

    return decoded.map<Company>((e) {
      final map = e as Map<String, dynamic>;
      return Company(
        code: (map['code'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        kana: '',
        market: (map['market'] ?? '').toString(),
        industry: (map['sector'] ?? '').toString(),
        price: 0,
        changePct: 0,
        marketCap: 0,
        volume: 0,
        favorite: false,
      );
    }).toList();
  }

  void dispose() {
    _client.close();
  }
}