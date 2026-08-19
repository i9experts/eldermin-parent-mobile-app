import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_service.dart';

/// Thin wrapper over the shared [Dio] instance — every [ParentApiService]
/// call goes through one of these so timeouts, auth headers, and 401
/// handling stay centralized in [DioService].
class BaseClient {
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final dio = DioService.getDio();
    debugPrint('GET → $url');

    return dio.get(
      url,
      queryParameters: queryParameters,
      options: Options(extra: {'requiresAuth': requiresAuth}),
    );
  }

  Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final dio = DioService.getDio();
    debugPrint('POST → $url');

    return dio.post(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(contentType: 'application/json', extra: {'requiresAuth': requiresAuth}),
    );
  }

  Future<Response> patch(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final dio = DioService.getDio();
    debugPrint('PATCH → $url');

    return dio.patch(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(contentType: 'application/json', extra: {'requiresAuth': requiresAuth}),
    );
  }
}
