import 'package:dio/dio.dart';

import '../session/auth_session_store.dart';
import 'api_config.dart';

class ApiClient {
  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthSessionStore.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  late final Dio dio;
}
