import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthResponse {
  final int userId;
  final String name;
  final String email;
  final int role;
  final String token;
  final bool requiresTwoFactor;
  final String challengeId;

  const AuthResponse({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    required this.requiresTwoFactor,
    required this.challengeId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: _toInt(json['userId'] ?? json['id']),
      name: (json['name'] ?? json['userName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: _toInt(json['role']),
      token: (json['token'] ?? '').toString(),
      requiresTwoFactor: json['requiresTwoFactor'] == true,
      challengeId: (json['challengeId'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final s = value.toString().trim().toUpperCase();
    if (s == 'ADMIN' || s == 'ROLE_ADMIN' || s == '2') return 2;
    if (s == 'USER' || s == 'ROLE_USER' || s == '1') return 1;

    return int.tryParse(s) ?? 0;
  }
}

class UserProfileResponse {
  final int id;
  final String name;
  final String email;
  final int role;
  final bool twoFactorEnabled;

  const UserProfileResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.twoFactorEnabled,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      id: AuthResponse._toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: AuthResponse._toInt(json['role']),
      twoFactorEnabled: json['twoFactorEnabled'] == true,
    );
  }
}

class AuthApiRepository {
  AuthApiRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'http://localhost:8080';

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(_extractErrorMessage(res.body, 'ログインに失敗しました'));
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required bool twoFactorEnabled,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');

    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userName': name,
        'email': email,
        'password': password,
        'twoFactorEnabled': twoFactorEnabled,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(_extractErrorMessage(res.body, '新規登録に失敗しました'));
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return AuthResponse.fromJson(json);
  }

  Future<void> logout(String? token) async {
    final uri = Uri.parse('$baseUrl/api/auth/logout');

    await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<UserProfileResponse> fetchUser(int userId, String token) async {
    final uri = Uri.parse('$baseUrl/api/users/$userId');

    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception(_extractErrorMessage(res.body, 'ユーザ情報の取得に失敗しました'));
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfileResponse.fromJson(json);
  }

  Future<AuthResponse> verifyTwoFactor({
    required String challengeId,
    required String code,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/2fa/verify');

    final res = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'challengeId': challengeId,
        'code': code,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(_extractErrorMessage(res.body, '2段階認証に失敗しました'));
    }

    return AuthResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> resendTwoFactor({
    required String challengeId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/2fa/resend');

    final res = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'challengeId': challengeId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(_extractErrorMessage(res.body, '認証コード再送に失敗しました'));
    }
  }

  Future<UserProfileResponse> updateUser({
    required int userId,
    required String token,
    required String name,
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/$userId');

    final res = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userName': name,
        'email': email,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(_extractErrorMessage(res.body, 'ユーザ情報の更新に失敗しました'));
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfileResponse.fromJson(json);
  }

  String _extractErrorMessage(String body, String fallback) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        if (json['message'] != null) {
          return json['message'].toString();
        }
        if (json['error'] != null) {
          return json['error'].toString();
        }
      }
    } catch (_) {}
    return fallback;
  }

  void dispose() {
    _client.close();
  }
}