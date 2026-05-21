import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../stock/domain/app_session.dart';

class AdminDashboardRepository {
  AdminDashboardRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String baseUrl = 'http://localhost:8080';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (AppSession.token != null && AppSession.token!.isNotEmpty)
          'Authorization': 'Bearer ${AppSession.token}',
      };

  Future<AdminDashboardSummary> fetchSummary() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/admin/dashboard'),
      headers: _headers,
    );

    if (res.statusCode != 200) {
      throw Exception('利用状況取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    return AdminDashboardSummary.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  void dispose() {
    _client.close();
  }
}

class AdminDashboardSummary {
  final int userCount;
  final int adminCount;
  final int favoriteCount;
  final int stockCount;
  final int companyProfileCount;
  final int twoFactorUserCount;

  const AdminDashboardSummary({
    required this.userCount,
    required this.adminCount,
    required this.favoriteCount,
    required this.stockCount,
    required this.companyProfileCount,
    required this.twoFactorUserCount,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      userCount: _toInt(json['userCount']),
      adminCount: _toInt(json['adminCount']),
      favoriteCount: _toInt(json['favoriteCount']),
      stockCount: _toInt(json['stockCount']),
      companyProfileCount: _toInt(json['companyProfileCount']),
      twoFactorUserCount: _toInt(json['twoFactorUserCount']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}