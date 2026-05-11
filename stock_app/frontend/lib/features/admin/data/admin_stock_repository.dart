import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../stock/domain/app_session.dart';

class AdminStockRepository {
  AdminStockRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String baseUrl = 'http://localhost:8080';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (AppSession.token != null && AppSession.token!.isNotEmpty)
          'Authorization': 'Bearer ${AppSession.token}',
      };

  Future<List<AdminStock>> fetchStocks() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/admin/stocks'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('銘柄一覧取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('銘柄一覧レスポンス不正: $decoded');
    }

    return decoded
        .map<AdminStock>((e) => AdminStock.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminStock> createStock({
    required String code,
    required String name,
    required String market,
    required String sector,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/admin/stocks'),
      headers: _headers,
      body: jsonEncode({
        'code': code,
        'name': name,
        'market': market,
        'sector': sector,
      }),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('銘柄登録失敗: status=${res.statusCode}, body=${res.body}');
    }

    return AdminStock.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AdminStock> updateStock({
    required String code,
    required String name,
    required String market,
    required String sector,
  }) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/api/admin/stocks/$code'),
      headers: _headers,
      body: jsonEncode({
        'code': code,
        'name': name,
        'market': market,
        'sector': sector,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('銘柄更新失敗: status=${res.statusCode}, body=${res.body}');
    }

    return AdminStock.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteStock(String code) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/api/admin/stocks/$code'),
      headers: _headers,
    );

    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('銘柄削除失敗: status=${res.statusCode}, body=${res.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}

class AdminStock {
  final String code;
  final String name;
  final String market;
  final String sector;

  const AdminStock({
    required this.code,
    required this.name,
    required this.market,
    required this.sector,
  });

  factory AdminStock.fromJson(Map<String, dynamic> json) {
    return AdminStock(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      market: (json['market'] ?? '').toString(),
      sector: (json['sector'] ?? '').toString(),
    );
  }
}