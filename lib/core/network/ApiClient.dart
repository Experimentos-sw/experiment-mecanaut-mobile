import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';

class ApiClient {
  ApiClient({
    required String? Function() getAuthToken,
    required Future<void> Function() onUnauthorized,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: AppConfig.apiBaseUrl,
           connectTimeout: const Duration(seconds: 30),
           receiveTimeout: const Duration(seconds: 30),
           sendTimeout: const Duration(seconds: 30),
           headers: const {
             'Content-Type': 'application/json',
             'Accept': 'application/json, text/plain, */*',
           },
         ),
       ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = getAuthToken();
          options.headers['Accept'] = 'application/json, text/plain, */*';
          options.headers['Content-Type'] = 'application/json';
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            final authHeader = options.headers['Authorization']?.toString();
            final maskedAuth = _maskAuth(authHeader);
            debugPrint(
              '[MECANAUT API] ${options.method} ${options.uri}\n'
              'Accept: ${options.headers['Accept']}\n'
              'Content-Type: ${options.headers['Content-Type']}\n'
              'Authorization: $maskedAuth\n'
              'Body: ${options.data}',
            );
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[MECANAUT API] ${response.requestOptions.method} ${response.requestOptions.uri}\n'
              'Status: ${response.statusCode}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            final request = error.requestOptions;
            final maskedAuth = _maskAuth(
              request.headers['Authorization']?.toString(),
            );
            debugPrint(
              '[MECANAUT API][ERROR] ${request.method} ${request.uri}\n'
              'Accept: ${request.headers['Accept']}\n'
              'Content-Type: ${request.headers['Content-Type']}\n'
              'Authorization: $maskedAuth\n'
              'Body: ${request.data}\n'
              'Status: ${error.response?.statusCode}\n'
              'Response: ${error.response?.data}',
            );
          }
          if (error.response?.statusCode == 401) {
            await onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  Dio get dio => _dio;

  String _maskAuth(String? authHeader) {
    if (authHeader == null || authHeader.isEmpty) return '<none>';
    final raw = authHeader.replaceFirst('Bearer ', '');
    if (raw.length <= 25) return 'Bearer $raw';
    return 'Bearer ${raw.substring(0, 25)}...';
  }

  ApiException mapDioException(DioException error) {
    return ApiException(
      message:
          error.response?.data?['message']?.toString() ??
          error.message ??
          'Unexpected network error',
      statusCode: error.response?.statusCode,
      details: error.response?.data,
    );
  }
}
