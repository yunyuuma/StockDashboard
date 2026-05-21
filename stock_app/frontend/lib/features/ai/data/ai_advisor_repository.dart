import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../stock/domain/app_session.dart';
import '../domain/ai_advisor_models.dart';
import '../domain/ai_stock_advisor_models.dart';
import '../domain/ai_portfolio_models.dart';
import '../domain/ai_trading_review_models.dart';
import '../domain/ai_chat_models.dart';

class AiAdvisorRepository {
  AiAdvisorRepository({http.Client? client})
    : _client = client ?? http.Client();

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

  Future<AiAdvisorResult> fetchAnalysis() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/ai-advisor'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('AI分析取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    return AiAdvisorResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<AiStockAdvisorResult> fetchStockAnalysis(String stockCode) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/ai-advisor/stocks/$stockCode'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('銘柄AI分析取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    return AiStockAdvisorResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<AiPortfolioAdvisor> fetchPortfolioAdvisor() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/ai-advisor/portfolio'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('AIポートフォリオ分析取得失敗');
    }

    return AiPortfolioAdvisor.fromJson(jsonDecode(response.body));
  }

  Future<AiTradingReview> fetchTradingReview() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/ai-advisor/trading-review'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('AI売買レビュー取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    return AiTradingReview.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<AiChatResponse> sendChatMessage(
    String message, {
    String? stockCode,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/ai-advisor/chat'),
      headers: _headers,
      body: jsonEncode({
        'message': message,
        'stockCode': stockCode,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('AIチャット送信失敗: status=${res.statusCode}, body=${res.body}');
    }

    return AiChatResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  void dispose() {
    _client.close();
  }
}
