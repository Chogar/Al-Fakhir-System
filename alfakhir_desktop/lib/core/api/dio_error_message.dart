import 'package:dio/dio.dart';

import '../../l10n/app_strings.dart';

/// Message lisible pour l’utilisateur (FR/AR) à partir d’une [DioException].
String userFacingDioMessage(DioException e, AppStrings str) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return str.networkTimeout;
    case DioExceptionType.connectionError:
      return str.networkUnreachable;
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      if (code == 401) return str.networkUnauthorized;
      final body = e.response?.data;
      if (body != null) return body.toString();
      return str.networkHttpError(code ?? 0);
    case DioExceptionType.cancel:
      return str.networkCancelled;
    default:
      break;
  }
  final m = e.message;
  if (m != null && m.isNotEmpty) return m;
  return str.networkUnknown;
}
