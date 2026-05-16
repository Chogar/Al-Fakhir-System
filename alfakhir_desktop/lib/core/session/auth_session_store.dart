import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale du JWT et du profil affiché (survit au hot restart).
final class AuthSessionStore {
  static const _kToken = 'alfakhir_access_token';
  static const _kUser = 'alfakhir_user_json';

  Future<void> save(String token, Map<String, dynamic> user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kUser, jsonEncode(user));
  }

  Future<({String token, Map<String, dynamic> user})?> load() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString(_kToken);
    if (token == null || token.isEmpty) return null;
    final rawUser = p.getString(_kUser);
    Map<String, dynamic> user = {};
    if (rawUser != null && rawUser.isNotEmpty) {
      final decoded = jsonDecode(rawUser);
      if (decoded is Map<String, dynamic>) user = decoded;
    }
    return (token: token, user: user);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kUser);
  }
}
