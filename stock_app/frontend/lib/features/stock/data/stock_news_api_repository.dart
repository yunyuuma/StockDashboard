import 'dart:convert';
import 'package:http/http.dart' as http;

import 'stock_news.dart';

class StockNewsApiRepository {
  StockNewsApiRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'http://localhost:8080';

  Future<List<StockNews>> fetchNews(String code) async {
    final uri = Uri.parse('$baseUrl/api/stocks/$code/news');

    final res = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception(
        'news fetch failed: status=${res.statusCode}, body=${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! List) {
      throw Exception('news response invalid: $decoded');
    }

    return decoded
        .map<StockNews>((e) => StockNews.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}