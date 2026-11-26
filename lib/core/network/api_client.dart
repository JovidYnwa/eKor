import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../l10n/strings.dart';
import 'api_exception.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    storage: ref.watch(tokenStorageProvider),
    lang: () => ref.read(langProvider),
  );
});

/// Thin wrapper around Dio for the eKor API.
///
/// - attaches the bearer token,
/// - on 401 refreshes the token once (single-flight) and retries,
/// - turns every failure into [ApiException].
class ApiClient {
  ApiClient({required this.storage, required this.lang}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: false),
      );
    }
  }

  final TokenStorage storage;
  final AppLang Function() lang;
  late final Dio _dio;

  /// Called when the session can't be refreshed (e.g. refresh token expired).
  void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<T>(path, queryParameters: _clean(query)));

  Future<T> post<T>(String path, {Object? body, String? idempotencyKey}) =>
      _send(() => _dio.post<T>(path, data: body, options: _idem(idempotencyKey)));

  Future<T> patch<T>(String path, {Object? body}) =>
      _send(() => _dio.patch<T>(path, data: body));

  Future<T> put<T>(String path, {Object? body}) =>
      _send(() => _dio.put<T>(path, data: body));

  Future<T> delete<T>(String path) => _send(() => _dio.delete<T>(path));

  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Options? _idem(String? key) =>
      key == null ? null : Options(headers: {'Idempotency-Key': key});

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) =>
      query == null ? null : (Map.of(query)..removeWhere((_, v) => v == null));

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept-Language'] = lang().code;
    final tokens = await storage.read();
    if (tokens != null && options.extra['skipAuth'] != true) {
      options.headers['Authorization'] = 'Bearer ${tokens.access}';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final isAuthCall = request.path.startsWith('/auth/');
    if (error.response?.statusCode != 401 ||
        isAuthCall ||
        request.extra['retried'] == true) {
      return handler.next(error);
    }

    final refreshed = await _refreshTokens();
    if (!refreshed) {
      // Tokens are cleared only when the server rejected the refresh token.
      if (await storage.read() == null) onSessionExpired?.call();
      return handler.next(error);
    }

    try {
      final tokens = await storage.read();
      request.headers['Authorization'] = 'Bearer ${tokens!.access}';
      request.extra['retried'] = true;
      handler.resolve(await _dio.fetch(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Refreshes tokens once even if many requests fail with 401 at the same time.
  Future<bool> _refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final tokens = await storage.read();
    if (tokens == null) return false;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': tokens.refresh},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = res.data!;
      await storage.save(AuthTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      ));
      return true;
    } on DioException catch (e) {
      // Only a definite rejection logs the user out; a network blip doesn't.
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await storage.clear();
      }
      return false;
    }
  }
}
