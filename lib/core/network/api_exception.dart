import 'package:dio/dio.dart';

import '../l10n/strings.dart';

/// Error returned by the eKor API: `{code, message, details}`.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    this.message,
    this.details,
  });

  /// HTTP status, or 0 when the request never reached the server.
  final int status;
  final String code;
  final String? message;
  final Object? details;

  bool get isNetwork => status == 0;
  bool get isUnauthorized => status == 401;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(status: 0, code: 'network', message: e.message);
    }
    final data = response.data;
    if (data is Map) {
      // FastAPI validation errors come as {detail: [...]}.
      final detail = data['detail'];
      return ApiException(
        status: response.statusCode ?? 0,
        code: (data['code'] as String?) ??
            (detail != null ? 'validation' : 'http_${response.statusCode}'),
        message: data['message'] as String?,
        details: data['details'] ?? detail,
      );
    }
    return ApiException(
      status: response.statusCode ?? 0,
      code: 'http_${response.statusCode}',
    );
  }

  /// Text to show to the user. Same rule as the website: show the server's
  /// message for client errors, a friendly generic one otherwise.
  String userMessage(S s) {
    if (isNetwork) return s.noInternet;
    if (status < 500 && message != null && message!.isNotEmpty) {
      return message!;
    }
    return s.serverError;
  }

  @override
  String toString() => 'ApiException($status, $code, $message)';
}

/// Converts any error into a user-facing message.
String errorText(Object error, S s) =>
    error is ApiException ? error.userMessage(s) : s.serverError;
