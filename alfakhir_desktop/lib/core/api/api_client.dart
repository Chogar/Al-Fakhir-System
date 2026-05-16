import 'package:dio/dio.dart';

import 'api_config.dart';

/// Client HTTP partagé (Bearer JWT après connexion).
final class ApiClient {
  ApiClient() : dio = Dio(_baseOptions()) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (err, handler) async {
          final reqPath = err.requestOptions.uri.path;
          final skipUnauthorized = reqPath.contains('/auth/login');
          if (!skipUnauthorized &&
              err.response?.statusCode == 401 &&
              _onUnauthorized != null) {
            _accessToken = null;
            await _onUnauthorized!.call();
          }
          handler.next(err);
        },
      ),
    );
  }

  final Dio dio;
  String? _accessToken;
  Future<void> Function()? _onUnauthorized;

  /// Token Bearer courant (null si déconnecté).
  String? get accessToken => _accessToken;

  /// Réinitialise session locale + UI si l’API répond 401 (JWT expiré ou invalide).
  void setOnUnauthorized(Future<void> Function()? callback) {
    _onUnauthorized = callback;
  }

  static BaseOptions _baseOptions() => BaseOptions(
        baseUrl: _normalizeBaseUrl(kApiBaseUrl),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

  /// Normalise l'URL de base pour tolérer les oublis de `/api` :
  ///  - `http://host:3000`        → `http://host:3000/api`
  ///  - `http://host:3000/`       → `http://host:3000/api`
  ///  - `http://host:3000/api`    → inchangé
  ///  - `http://host:3000/api/`   → `http://host:3000/api`
  /// Préserve un chemin déjà personnalisé (ex. `/v2`).
  static String _normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final hasMeaningfulPath =
        uri.path.isNotEmpty && uri.path != '/' && uri.path != '';
    if (!hasMeaningfulPath) {
      return '$url/api';
    }
    return url;
  }

  void setAccessToken(String? token) {
    _accessToken = token;
  }
}
