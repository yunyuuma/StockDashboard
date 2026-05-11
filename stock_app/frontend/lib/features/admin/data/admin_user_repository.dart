import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../stock/domain/app_session.dart';

class AdminUserRepository {
  AdminUserRepository({http.Client? client}) : _client = client ?? http.Client();

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

  Future<List<AdminUser>> fetchUsers() async {
    final uri = Uri.parse('$baseUrl/api/admin/users');

    final res = await _client.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('ユーザ一覧取得失敗: status=${res.statusCode}, body=${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('ユーザ一覧レスポンス不正: $decoded');
    }

    return decoded
        .map<AdminUser>((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminUser> updateRole({
    required int userId,
    required String role,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/users/$userId/role');

    final res = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode({'role': role}),
    );

    if (res.statusCode != 200) {
      throw Exception('権限更新失敗: status=${res.statusCode}, body=${res.body}');
    }

    return AdminUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteUser(int userId) async {
    final uri = Uri.parse('$baseUrl/api/admin/users/$userId');

    final res = await _client.delete(uri, headers: _headers);

    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(
        'ユーザ削除失敗: status=${res.statusCode}, body=${res.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class AdminUser {
  final int userId;
  final String userName;
  final String email;
  final String role;
  final bool twoFactorEnabled;

  const AdminUser({
    required this.userId,
    required this.userName,
    required this.email,
    required this.role,
    required this.twoFactorEnabled,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      userId: _toInt(json['userId'] ?? json['id']),
      userName: (json['userName'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'USER').toString().toUpperCase(),
      twoFactorEnabled: _toBool(json['twoFactorEnabled']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    final s = value.toString().toLowerCase();
    return s == 'true' || s == '1';
  }
}