import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionStore {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user_json';

  static String? token;
  static Map<String, dynamic>? user;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString(_tokenKey);
    final raw = p.getString(_userKey);
    if (raw != null && raw.isNotEmpty) {
      user = jsonDecode(raw) as Map<String, dynamic>;
    }
  }

  static Future<void> save(String t, Map<String, dynamic> u) async {
    token = t;
    user = u;
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, t);
    await p.setString(_userKey, jsonEncode(u));
  }

  static Future<void> clear() async {
    token = null;
    user = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
    await p.remove(_userKey);
  }
}
