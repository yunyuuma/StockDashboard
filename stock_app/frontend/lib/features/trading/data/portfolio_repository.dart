import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../stock/domain/app_session.dart';
import '../domain/portfolio_models.dart';

class PortfolioRepository {
  PortfolioRepository({http.Client? client}) : _client = client ?? http.Client();

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

  Future<PortfolioSummary> fetchPortfolio() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/trading/portfolio'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('ポートフォリオ取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    return PortfolioSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void dispose() {
    _client.close();
  }
}