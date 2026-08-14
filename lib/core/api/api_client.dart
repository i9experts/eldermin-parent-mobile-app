import 'package:dio/dio.dart';
import '../auth/secure_storage_service.dart';

/// Thrown when the backend returns an error - the UI checks statusCode
/// to route appropriately (401 -> login, 403 -> access-denied message,
/// everything else -> the message itself).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  // Same production API every other Eldermin client (web ERP) talks to.
  // Override via --dart-define=API_BASE_URL=... for local backend testing.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.eldermin.com/api/v1',
  );

  late final Dio _dio;
  final SecureStorageService _storage;
  void Function()? onUnauthorized;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        return handler.next(error);
      },
    ));
  }

  Dio get raw => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return res.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final res = await _dio.patch(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    String message = 'Something went wrong. Please try again.';
    if (body is Map && body['message'] != null) {
      message = body['message'] is List ? (body['message'] as List).join(', ') : body['message'].toString();
    } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Check your internet and try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Couldn\'t reach Eldermin. Check your internet connection.';
    }
    return ApiException(message, statusCode: status);
  }
}
