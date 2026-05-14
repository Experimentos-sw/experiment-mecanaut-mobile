import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/auth/data/dtos/sign_in_request.dart';
import 'package:mecanaut_mobile/features/auth/data/dtos/sign_in_response.dart';
import 'package:mecanaut_mobile/features/auth/data/dtos/sign_up_request.dart';
import 'package:mecanaut_mobile/features/auth/data/dtos/user_profile.dart';

class AuthService {
  AuthService({Dio? dio})
    : _dio =
          dio ??
          Dio(
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
          );

  final Dio _dio;

  Future<SignInResponse> signIn(SignInRequest request) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[MECANAUT AUTH] POST ${_dio.options.baseUrl}${ApiPaths.signIn}',
        );
      }
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiPaths.signIn,
        data: request.toMap(),
      );
      if (kDebugMode) {
        debugPrint('[MECANAUT AUTH] Status: ${response.statusCode}');
        debugPrint('[MECANAUT AUTH] Response: ${response.data}');
      }
      return SignInResponse.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[MECANAUT AUTH][ERROR] Status: ${error.response?.statusCode}',
        );
        debugPrint('[MECANAUT AUTH][ERROR] Response: ${error.response?.data}');
      }
      throw ApiException(
        message: _extractErrorMessage(
          error,
          'No se pudo iniciar sesion. Verifica usuario/correo y contrasena.',
        ),
        statusCode: error.response?.statusCode,
        details: error.response?.data,
      );
    }
  }

  Future<void> signUp(SignUpRequest request) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[MECANAUT AUTH] POST ${_dio.options.baseUrl}${ApiPaths.signUp}',
        );
      }
      await _dio.post<dynamic>(ApiPaths.signUp, data: request.toMap());
    } on DioException catch (error) {
      throw ApiException(
        message: _extractErrorMessage(error, 'No se pudo crear la cuenta.'),
        statusCode: error.response?.statusCode,
        details: error.response?.data,
      );
    }
  }

  Future<UserProfile> getUserById({
    required int userId,
    required String token,
  }) async {
    try {
      if (kDebugMode) {
        final masked = token.length <= 25
            ? token
            : '${token.substring(0, 25)}...';
        debugPrint(
          '[MECANAUT AUTH] GET ${_dio.options.baseUrl}${ApiPaths.users}/$userId\n'
          'Accept: application/json, text/plain, */*\n'
          'Content-Type: application/json\n'
          'Authorization: Bearer $masked',
        );
      }
      final Response<dynamic> response = await _dio.get<dynamic>(
        '${ApiPaths.users}/$userId',
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Accept': 'application/json, text/plain, */*',
            'Content-Type': 'application/json',
          },
        ),
      );
      if (kDebugMode) {
        debugPrint('[MECANAUT AUTH] Status: ${response.statusCode}');
        debugPrint('[MECANAUT AUTH] Response: ${response.data}');
      }
      return UserProfile.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[MECANAUT AUTH][ERROR] Status: ${error.response?.statusCode}',
        );
        debugPrint('[MECANAUT AUTH][ERROR] Response: ${error.response?.data}');
      }
      throw ApiException(
        message: _extractErrorMessage(error, 'No se pudo recuperar el perfil.'),
        statusCode: error.response?.statusCode,
        details: error.response?.data,
      );
    }
  }

  String _extractErrorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          fallback;
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return fallback;
  }
}
