import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/app_preferences.dart';

/// Builds the single shared [Dio] instance every network call goes
/// through — timeouts, the bearer token, and the "session died" 401
/// handling all live here so [BaseClient] stays a thin HTTP wrapper.
///
/// Kept free of any dependency on GetX controllers (core must not depend
/// on features): [InitialBinding] wires [onUnauthorized] to the session
/// controller's logout once it's registered.
class DioService {
  DioService._();

  static void Function()? onUnauthorized;
  static Dio? _dio;

  static Dio getDio() {
    final existing = _dio;
    if (existing != null) return existing;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final requiresAuth = options.extra['requiresAuth'] ?? false;
          if (requiresAuth) {
            final token = await AppPreferences.getAccessTokenAsync();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          debugPrint('➡️ ${options.method} ${options.path}');
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('❌ Dio error ${error.response?.statusCode}: ${error.requestOptions.path}');

          // Only a 401 on a request that actually sent a token means the
          // session itself died — an unauthenticated call (e.g. OTP
          // request/verify) returning 401 just means "wrong code", not a
          // session drop, and must be handled by the caller normally.
          final requiresAuth = error.requestOptions.extra['requiresAuth'] ?? false;
          if (error.response?.statusCode == 401 && requiresAuth) {
            onUnauthorized?.call();
          }

          handler.next(error);
        },
      ),
    );

    return _dio = dio;
  }
}
