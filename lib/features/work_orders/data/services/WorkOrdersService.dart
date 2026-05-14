import 'package:dio/dio.dart';
import 'package:mecanaut_mobile/core/config/AppConfig.dart';
import 'package:mecanaut_mobile/core/network/ApiException.dart';
import 'package:mecanaut_mobile/features/work_orders/data/models/create_work_order_request.dart';
import 'package:mecanaut_mobile/features/work_orders/data/models/work_order_item.dart';

class WorkOrdersService {
  WorkOrdersService(this._dio);

  final Dio _dio;

  Future<List<WorkOrderItem>> getByProductionLine(int productionLineId) async {
    try {
      final response = await _dio.get<dynamic>(
        '${ApiPaths.workOrders}/by-production-line/$productionLineId',
      );
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => WorkOrderItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e, 'No se pudo cargar ordenes de trabajo.');
    }
  }

  Future<List<WorkOrderItem>> getToExecuteByProductionLine(
    int productionLineId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '${ApiPaths.workOrders}/by-production-line-to-execute/$productionLineId',
      );
      final list = response.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => WorkOrderItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e, 'No se pudo cargar ordenes por ejecutar.');
    }
  }

  Future<WorkOrderItem> getById(int id) async {
    try {
      final response = await _dio.get<dynamic>('${ApiPaths.workOrders}/$id');
      return WorkOrderItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo cargar la orden.');
    }
  }

  Future<WorkOrderItem> create(CreateWorkOrderRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiPaths.workOrders,
        data: request.toMap(),
      );
      return WorkOrderItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo crear la orden.');
    }
  }

  Future<WorkOrderItem> complete(int id) async {
    try {
      final response = await _dio.put<dynamic>(
        '${ApiPaths.workOrders}/$id/complete',
      );
      return WorkOrderItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo completar la orden.');
    }
  }

  Future<WorkOrderItem> assignTechnicians(
    int id,
    List<int?> technicianIds,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '${ApiPaths.workOrders}/$id/technicians',
        data: technicianIds,
      );
      return WorkOrderItem.fromMap(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e, 'No se pudo asignar tecnicos.');
    }
  }

  ApiException _map(DioException e, String fallback) {
    return ApiException(
      message:
          e.response?.data?['message']?.toString() ??
          e.response?.data?['error']?.toString() ??
          e.response?.data?.toString() ??
          fallback,
      statusCode: e.response?.statusCode,
      details: e.response?.data,
    );
  }
}
