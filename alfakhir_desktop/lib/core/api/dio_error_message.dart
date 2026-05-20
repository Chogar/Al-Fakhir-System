import 'package:dio/dio.dart';

import '../../l10n/app_strings.dart';

String userFacingDioMessage(DioException e, AppStrings str) {
  final status = e.response?.statusCode;
  final data = e.response?.data;
  if (data is Map && data['message'] != null) {
    final m = data['message'];
    if (m is String) return m;
    if (m is List) return m.join(', ');
  }
  if (status == 401) return str.authInvalid;
  if (status == 403) return str.forbidden;
  if (e.type == DioExceptionType.connectionError) {
    return str.apiUnreachable;
  }
  return e.message ?? str.genericError;
}
