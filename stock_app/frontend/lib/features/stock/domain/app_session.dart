import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static const _keyToken = 'token';
  static const _keyUserId = 'userId';
  static const _keyName = 'name';
  static const _keyEmail = 'email';
  static const _keyRole = 'role';

  static String? token;
  static int? userId;
  static String? name;
  static String? email;
  static int? role;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;
  static bool get isAdmin => role == 2;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_keyToken);
    userId = prefs.getInt(_keyUserId);
    name = prefs.getString(_keyName);
    email = prefs.getString(_keyEmail);
    role = prefs.getInt(_keyRole);
  }

  static Future<void> save({
    required String token,
    required int userId,
    required String name,
    required String email,
    required int role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setInt(_keyRole, role);

    AppSession.token = token;
    AppSession.userId = userId;
    AppSession.name = name;
    AppSession.email = email;
    AppSession.role = role;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);

    token = null;
    userId = null;
    name = null;
    email = null;
    role = null;
  }
}