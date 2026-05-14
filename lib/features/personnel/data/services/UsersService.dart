import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/create_user_request.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/update_user_request.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/user_item.dart';

class UsersService {
  UsersService(this._dio);

  final Dio _dio;

  Future<List<UserItem>> getUsers() async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.users);
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => UserItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapException(e, 'No se pudo cargar el personal.');
    }
  }

  Future<UserItem> getUserById(int id) async {
    try {
      final response = await _dio.get<dynamic>('${ApiPaths.users}/$id');
      return UserItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapException(e, 'No se pudo cargar el usuario.');
    }
  }

  Future<UserItem> createUser(CreateUserRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiPaths.users,
        data: request.toMap(),
      );
      return UserItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapException(e, 'No se pudo crear el usuario.');
    }
  }

  Future<UserItem> updateUser(int id, UpdateUserRequest request) async {
    try {
      final response = await _dio.put<dynamic>(
        '${ApiPaths.users}/$id',
        data: request.toMap(),
      );
      return UserItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapException(e, 'No se pudo actualizar el usuario.');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete<dynamic>('${ApiPaths.users}/$id');
    } on DioException catch (e) {
      throw _mapException(e, 'No se pudo eliminar el usuario.');
    }
  }

  ApiException _mapException(DioException e, String fallback) {
    return ApiException(
      message:
          e.response?.data?['message']?.toString() ??
          e.response?.data?['error']?.toString() ??
          fallback,
      statusCode: e.response?.statusCode,
      details: e.response?.data,
    );
  }
}
