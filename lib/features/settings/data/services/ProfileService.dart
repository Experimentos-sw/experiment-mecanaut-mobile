import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/update_user_request.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/user_item.dart';

class ProfileService {
  ProfileService(this._dio);

  final Dio _dio;

  Future<UserItem> getById(int id) async {
    try {
      final response = await _dio.get<dynamic>('${ApiPaths.users}/$id');
      return UserItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudo cargar el perfil.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<UserItem> update(int id, UpdateUserRequest request) async {
    try {
      final response = await _dio.put<dynamic>('${ApiPaths.users}/$id', data: request.toMap());
      return UserItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudo actualizar el perfil.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}

