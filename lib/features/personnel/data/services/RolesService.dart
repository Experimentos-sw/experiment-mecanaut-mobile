import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/role_item.dart';

class RolesService {
  RolesService(this._dio);

  final Dio _dio;

  Future<List<RoleItem>> getRoles() async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.roles);
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => RoleItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.response?.data?['error']?.toString() ??
            'No se pudieron cargar los roles.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }
}
