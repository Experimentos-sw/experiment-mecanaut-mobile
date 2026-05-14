import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/maintenance_plans/data/models/dynamic_maintenance_plan_dto.dart';

class DynamicMaintenancePlansService {
  DynamicMaintenancePlansService(this._dio);

  final Dio _dio;

  Future<List<DynamicMaintenancePlanDto>> getByPlantLine(String plantLineId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiPaths.dynamicMaintenancePlans,
        queryParameters: <String, dynamic>{'plantLineId': plantLineId},
      );
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list.map((e) => DynamicMaintenancePlanDto.fromMap(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? 'No se pudieron cargar planes dinamicos.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<DynamicMaintenancePlanDto> create(SaveDynamicMaintenancePlanRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiPaths.dynamicMaintenancePlans,
        data: request.toMap(),
      );
      return DynamicMaintenancePlanDto.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? e.response?.data?.toString() ?? 'No se pudo crear plan dinamico.',
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  Future<int?> testPlanId({
    required int machineId,
    required int metricId,
    required double amount,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '${ApiPaths.dynamicMaintenancePlans}/test-plan-id',
        queryParameters: <String, dynamic>{
          'machineId': machineId,
          'metricId': metricId,
          'amount': amount,
        },
      );
      final raw = response.data;
      if (raw == null) return null;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw.toString());
    } on DioException catch (_) {
      return null;
    }
  }
}

