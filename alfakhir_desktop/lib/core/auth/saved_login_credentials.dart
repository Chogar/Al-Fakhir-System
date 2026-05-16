import 'package:shared_preferences/shared_preferences.dart';

/// Identifiants mémorisés (desktop) via SharedPreferences.
///
/// Sur Windows, on évite `flutter_secure_storage` (plugin natif ATL / atlstr.h).
final class SavedLoginCredentials {
  SavedLoginCredentials._();

  static const _kRemember = 'login_remember_credentials';
  static const _kSkipAutoOnce = 'login_skip_auto_login_once';
  static const _kUsername = 'login_saved_username';
  static const _kPassword = 'login_saved_password';

  static Future<({bool remember, String? username, String? password})>
      load() async {
    final p = await SharedPreferences.getInstance();
    final remember = p.getBool(_kRemember) ?? false;
    if (!remember) {
      await p.remove(_kUsername);
      await p.remove(_kPassword);
      return (remember: false, username: null, password: null);
    }
    return (
      remember: true,
      username: p.getString(_kUsername),
      password: p.getString(_kPassword),
    );
  }

  static Future<void> save(String username, String password) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemember, true);
    await p.setString(_kUsername, username);
    await p.setString(_kPassword, password);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemember, false);
    await p.remove(_kUsername);
    await p.remove(_kPassword);
  }

  static Future<void> skipNextAutoLogin() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSkipAutoOnce, true);
  }

  static Future<bool> consumeSkipNextAutoLogin() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getBool(_kSkipAutoOnce) ?? false;
    if (v) await p.remove(_kSkipAutoOnce);
    return v;
  }
}
