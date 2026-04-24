import 'dart:convert';
import 'package:http/http.dart' as http;

import '../domain/app_session.dart';
import '../domain/company.dart';

class FavoriteApiRepository {
  FavoriteApiRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'http://localhost:8080';

  Map<String, String> get _headers {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (AppSession.token != null && AppSession.token!.isNotEmpty)
        'Authorization': 'Bearer ${AppSession.token}',
    };
  }

  Future<List<Company>> fetchFavorites({required int userId}) async {
    final uri = Uri.parse('$baseUrl/api/favorites?userId=$userId');

    final res = await _client.get(
      uri,
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'favorites fetch failed: status=${res.statusCode}, body=${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('favorites response invalid: $decoded');
    }

    return decoded.map<Company>((e) {
      final map = e as Map<String, dynamic>;
      return Company(
        code: (map['code'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        kana: '',
        market: (map['market'] ?? '').toString(),
        industry: (map['sector'] ?? map['industry'] ?? '').toString(),
        price: 0,
        changePct: 0,
        marketCap: 0,
        volume: 0,
        favorite: true,
      );
    }).toList();
  }

  Future<void> addFavorite({
    required int userId,
    required String stockCode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/favorites');

    final res = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'stockCode': stockCode,
      }),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        'favorite add failed: status=${res.statusCode}, body=${res.body}',
      );
    }
  }

  Future<void> deleteFavorite({
    required int userId,
    required String stockCode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/favorites/$stockCode?userId=$userId');

    final res = await _client.delete(
      uri,
      headers: _headers,
    );

    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(
        'favorite delete failed: status=${res.statusCode}, body=${res.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}