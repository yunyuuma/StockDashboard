import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/app_session.dart';

class UserApiRepository {
  UserApiRepository({http.Client? client}) : _client = client ?? http.Client();

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

  Future<UserProfile> fetchUser({required int userId}) async {
    final uri = Uri.parse('$baseUrl/api/users/me');

    final res = await _client.get(uri, headers: _headers);

    debugPrint('USER PROFILE STATUS: ${res.statusCode}');
    debugPrint('USER PROFILE BODY: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception(
        'ユーザ情報取得失敗: status=${res.statusCode}, body=${res.body}',
      );
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfile.fromJson(map);
  }

  Future<UserProfile> updateTwoFactorSetting({
    required bool enabled,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/me/2fa');

    final res = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'enabled': enabled,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(
        '2段階認証設定更新失敗: status=${res.statusCode}, body=${res.body}',
      );
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfile.fromJson(map);
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/me/password');

    final res = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'パスワード変更失敗: status=${res.statusCode}, body=${res.body}',
      );
    }
  }

  Future<UserProfile> updateUser({
    required int userId,
    required String name,
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/me');

    final res = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'userName': name,
        'email': email,
      }),
    );

    debugPrint('USER UPDATE STATUS: ${res.statusCode}');
    debugPrint('USER UPDATE BODY: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception(
        'ユーザ情報更新失敗: status=${res.statusCode}, body=${res.body}',
      );
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfile.fromJson(map);
  }

  void dispose() {
    _client.close();
  }
}

class UserProfile {
  final int id;
  final String name;
  final String email;
  final int role;
  final bool twoFactorEnabled;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.twoFactorEnabled,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _toInt(json['id'] ?? json['userId']),
      name: (json['name'] ?? json['userName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: _toInt(json['role'] ?? json['roleCode']),
      twoFactorEnabled: _toBool(
        json['twoFactorEnabled'] ?? json['two_factor_enabled'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final s = value.toString().toUpperCase();

    if (s == 'ADMIN' || s == 'ROLE_ADMIN') return 2;
    if (s == 'USER' || s == 'ROLE_USER') return 1;

    return int.tryParse(s) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;
    final s = value.toString().toLowerCase();
    return s == 'true' || s == '1';
  }
}